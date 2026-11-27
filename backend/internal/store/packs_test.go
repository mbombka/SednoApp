package store

import (
	"context"
	"sync"
	"testing"
	"time"
)

func TestPackReservationsAcrossInstallations(t *testing.T) {
	ctx, db := emulatorDB(t)
	now := time.Date(2026, 11, 27, 23, 59, 0, 0, time.UTC)
	s := &Store{DB: db, Now: func() time.Time { return now }}
	const token = "synthetic-pack"
	accountID := newID()
	identities := [2]string{newID(), newID()}
	installations := [2]string{hash("first"), hash("second")}
	accountRef := s.doc("verified_accounts", docID(accountID))
	// Seed the Firestore format written by the .NET runtime.
	if _, err := accountRef.Set(ctx, map[string]any{
		"Id": accountID, "InstallationHashes": installations[:], "Deleting": false,
		"PackCredits": map[string]int{hash(token): 1},
	}); err != nil {
		t.Fatal(err)
	}
	for i, id := range identities {
		if _, err := s.doc("guest_identities", docID(id)).Set(ctx, Identity{Id: id, InstallationHash: installations[i], AccountId: &accountID}); err != nil {
			t.Fatal(err)
		}
	}

	type result struct {
		id, state string
		quota     Quota
		err       error
	}
	var both sync.WaitGroup
	outcomes := make(chan result, len(identities))
	for _, id := range identities {
		both.Go(func() {
			state, quota, err := s.Reserve(ctx, id, "last", "synthetic-fingerprint", false)
			outcomes <- result{id, state, quota, err}
		})
	}
	both.Wait()
	close(outcomes)
	var reserved, blocked string
	for outcome := range outcomes {
		if outcome.err != nil || outcome.quota.PackRemaining != 0 || outcome.quota.PackBalance != 1 || outcome.quota.Remaining != 5 {
			t.Fatalf("unexpected reservation: %+v", outcome)
		}
		switch outcome.state {
		case "reserved":
			reserved = outcome.id
		case "pack_reserved":
			blocked = outcome.id
		}
	}
	if reserved == "" || blocked == "" {
		t.Fatal("exactly one installation must reserve the last purchased use")
	}
	now = now.Add(time.Minute)
	completed, err := s.Finish(ctx, reserved, "last", false)
	if err != nil || completed {
		t.Fatalf("failed request consumed a pack use: %v", err)
	}
	state, quota, err := s.Reserve(ctx, blocked, "retry", "synthetic-fingerprint", false)
	if err != nil || state != "reserved" || quota.PackBalance != 1 {
		t.Fatalf("pack use was unavailable after failure and UTC reset: %s, %v", state, err)
	}
	completed, err = s.Finish(ctx, blocked, "retry", true)
	if err != nil || !completed {
		t.Fatalf("successful request failed to consume the last pack use: %v", err)
	}
	state, quota, err = s.Reserve(ctx, reserved, "daily", "synthetic-fingerprint", false)
	if err != nil || state != "reserved" || quota.PackBalance != 0 || quota.Remaining != 4 {
		t.Fatalf("daily allowance was unavailable after the pack was spent: %s, %+v, %v", state, quota, err)
	}
}

type packSnapshot struct{ PlayPack }

func (p packSnapshot) LookupPack(context.Context, string) (PlayPack, error) { return p.PlayPack, nil }

func (p packSnapshot) ConsumePack(context.Context, string) error {
	panic("revoked purchase must never be consumed")
}

func TestPackRefundBeforeVerification(t *testing.T) {
	ctx, db := emulatorDB(t)
	s := &Store{DB: db, Now: time.Now}
	accountID := newID()
	ref := s.doc("verified_accounts", docID(accountID))
	if _, err := ref.Create(ctx, Account{Id: accountID}); err != nil {
		t.Fatal(err)
	}
	const token = "synthetic-refund"
	p := Packs{Store: s, Play: packSnapshot{PlayPack{State: "PURCHASED", Quantity: 1, Product: PackProductID, Binding: binding(accountID)}}}
	if err := p.Notify(ctx, token, true); err != nil {
		t.Fatal(err)
	}
	if state, err := p.Verify(ctx, accountID, token); err != nil || state != "invalid" {
		t.Fatalf("stale Play snapshot restored a refunded purchase: %q, %v", state, err)
	}
}
