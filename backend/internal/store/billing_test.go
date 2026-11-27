package store

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/mbombka/SednoApp/backend/internal/keyring"
)

type testPlay struct {
	status        map[string]PlaySubscription
	failed        bool
	lookups, acks int
}

func (p *testPlay) Lookup(_ context.Context, token string) (PlaySubscription, error) {
	p.lookups++
	if p.failed {
		return PlaySubscription{}, errors.New("synthetic Play API failure")
	}
	return p.status[token], nil
}
func (p *testPlay) Acknowledge(_ context.Context, token string) error {
	p.acks++
	status := p.status[token]
	status.Acknowledged = true
	p.status[token] = status
	return nil
}

func TestBillingRefreshAndNotification(t *testing.T) {
	ctx, db := emulatorDB(t)
	now := time.Now().UTC()
	s := &Store{DB: db, Now: func() time.Time { return now }}
	account := Account{Id: newID(), CreatedAt: now, FirebaseUid: "synthetic", Provider: "google"}
	if _, err := s.doc("verified_accounts", docID(account.Id)).Create(ctx, account); err != nil {
		t.Fatal(err)
	}
	if _, err := s.doc("account_bindings", binding(account.Id)).Create(ctx, accountPointer{account.Id}); err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	if err := keyring.Initialize(dir); err != nil {
		t.Fatal(err)
	}
	p, err := keyring.Open(dir)
	if err != nil {
		t.Fatal(err)
	}
	const first, second = "synthetic-purchase-1", "synthetic-purchase-2"
	until := now.Add(time.Hour)
	play := &testPlay{status: map[string]PlaySubscription{
		first:  {State: "SUBSCRIPTION_STATE_ACTIVE", ExpiresAt: &until, Binding: binding(account.Id)},
		second: {State: "SUBSCRIPTION_STATE_ACTIVE", ExpiresAt: &until, Binding: binding(account.Id), LinkedToken: first},
	}}
	b := &Billing{Store: s, Play: play, Protection: p}
	result, err := b.Verify(ctx, account.Id, first)
	if err != nil || !result.Active || play.acks != 1 {
		t.Fatalf("purchase verification failed: %v", err)
	}
	paid, err := b.Paid(ctx, &account.Id)
	if err != nil || !paid || play.lookups != 1 {
		t.Fatalf("fresh verified purchase was not reused: %v", err)
	}
	now = now.Add(16 * time.Minute)
	play.failed = true
	paid, err = b.Paid(ctx, &account.Id)
	if err != nil || paid || play.lookups != 2 {
		t.Fatalf("stale verification did not fail closed: %v", err)
	}
	paid, err = b.Paid(ctx, &account.Id)
	if err != nil || paid || play.lookups != 2 {
		t.Fatalf("refresh cooldown did not apply: %v", err)
	}
	play.failed = false
	if err := b.Notify(ctx, "synthetic-notification", second); err != nil {
		t.Fatal(err)
	}
	lookups := play.lookups
	if err := b.Notify(ctx, "synthetic-notification", second); err != nil || lookups != play.lookups {
		t.Fatalf("notification was processed twice: %v", err)
	}
	doc, err := read[purchase](ctx, nil, s.doc("play_purchases", hash(first)))
	if err != nil || doc == nil || !doc.Revoked {
		t.Fatalf("replaced purchase not revoked: %v", err)
	}
	doc, err = read[purchase](ctx, nil, s.doc("play_purchases", hash(second)))
	if err != nil || doc == nil || doc.ProtectedToken == "" || doc.ProtectedToken == second || doc.RefreshNotBefore != nil {
		t.Fatalf("invalid stored purchase: %v", err)
	}
	paid, err = b.Paid(ctx, &account.Id)
	if err != nil || !paid || play.acks != 2 {
		t.Fatalf("replacement purchase did not give access: %v", err)
	}
}
