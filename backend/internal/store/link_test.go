package store

import (
	"context"
	"fmt"
	"net"
	"os"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
)

func emulatorDB(t *testing.T) (context.Context, *firestore.Client) {
	t.Helper()
	address := os.Getenv("FIRESTORE_EMULATOR_HOST")
	if address == "" {
		t.Skip("Firestore emulator is required")
	}
	host, _, err := net.SplitHostPort(address)
	if err != nil || net.ParseIP(host) == nil || !net.ParseIP(host).IsLoopback() {
		t.Fatal("tests require a loopback emulator")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	t.Cleanup(cancel)
	db, err := firestore.NewClient(ctx, fmt.Sprintf("demo-sedno-%x", time.Now().UnixNano()))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = db.Close() })
	return ctx, db
}

func TestLinkPreservesInstallationUsage(t *testing.T) {
	ctx, db := emulatorDB(t)
	s := &Store{DB: db, Now: time.Now}
	key := make([]byte, 32)
	verified := VerifiedIdentity{UID: "synthetic-uid", Provider: "email", AuthTime: time.Now().Unix()}
	fresh := func(_ context.Context, uid string, authTime int64) (bool, error) {
		return uid == verified.UID && authTime == verified.AuthTime, nil
	}
	for index, id := range []string{"installation-a", "installation-b"} {
		guest, err := s.CreateGuest(ctx, id, key)
		if err != nil {
			t.Fatal(err)
		}
		identity, err := s.Authenticate(ctx, guest.AccessToken, key, nil)
		if err != nil || identity == nil {
			t.Fatalf("guest authentication failed: %v", err)
		}
		kind, _, err := s.Reserve(ctx, identity.IdentityID, "synthetic", "fingerprint", false)
		if err != nil || kind != "reserved" {
			t.Fatalf("reserve outcome %s: %v", kind, err)
		}
		done, err := s.Finish(ctx, identity.IdentityID, "synthetic", true)
		if err != nil || !done {
			t.Fatalf("finish failed: %v", err)
		}
		unverified := verified
		if session, err := s.Link(ctx, identity, unverified, key, fresh); err != nil || session != nil {
			t.Fatalf("unverified email acquired access: %v", err)
		}
		email := verified
		email.EmailVerified = true
		session, err := s.Link(ctx, identity, email, key, fresh)
		if err != nil || session == nil {
			t.Fatalf("link failed: %v", err)
		}
		if session.Quota.Used != index+1 {
			t.Fatalf("account usage after linking: %d", session.Quota.Used)
		}
		for _, token := range []string{guest.AccessToken, session.AccessToken} {
			old, err := s.Authenticate(ctx, token, key, nil)
			if err != nil || old != nil {
				t.Fatalf("session was accepted without fresh account access: %v", err)
			}
		}
		account, err := s.Authenticate(ctx, session.AccessToken, key, fresh)
		if err != nil || account == nil || account.AccountID == nil || *account.AccountID != session.Account.ID {
			t.Fatalf("account authentication failed: %v", err)
		}
	}
}

func TestCleanupResumesInterruptedDeletion(t *testing.T) {
	ctx, db := emulatorDB(t)
	s := &Store{DB: db, Now: time.Now}
	key := make([]byte, 32)
	verified := VerifiedIdentity{UID: "synthetic-uid", Provider: "google", AuthTime: time.Now().Unix()}
	fresh := func(_ context.Context, uid string, authTime int64) (bool, error) {
		return uid == verified.UID && authTime == verified.AuthTime, nil
	}
	guest, err := s.CreateGuest(ctx, "shared", key)
	if err != nil {
		t.Fatal(err)
	}
	guestSession, err := s.Authenticate(ctx, guest.AccessToken, key, nil)
	if err != nil || guestSession == nil {
		t.Fatalf("guest authentication failed: %v", err)
	}
	linked, err := s.Link(ctx, guestSession, verified, key, fresh)
	if err != nil || linked == nil {
		t.Fatalf("link failed: %v", err)
	}
	account, err := s.Authenticate(ctx, linked.AccessToken, key, fresh)
	if err != nil || account == nil {
		t.Fatalf("account authentication failed: %v", err)
	}
	other, err := s.CreateGuest(ctx, "shared", key)
	if err != nil {
		t.Fatal(err)
	}
	for _, id := range []string{account.IdentityID, other.Account.ID} {
		kind, _, err := s.Reserve(ctx, id, "synthetic", "fingerprint", false)
		if err != nil || kind != "reserved" {
			t.Fatalf("reserve outcome %s: %v", kind, err)
		}
		done, err := s.Finish(ctx, id, "synthetic", true)
		if err != nil || !done {
			t.Fatalf("finish failed: %v", err)
		}
	}
	deleted, err := s.DeleteAccount(ctx, account, verified, fresh, func(context.Context, string) error {
		return fmt.Errorf("synthetic interruption")
	})
	if err == nil || deleted {
		t.Fatal("expected interrupted deletion")
	}
	if session, err := s.Authenticate(ctx, linked.AccessToken, key, fresh); err != nil || session != nil {
		t.Fatalf("deleting account retained access: %v", err)
	}
	err = s.Cleanup(ctx, func(_ context.Context, uid string) error {
		if uid != verified.UID {
			t.Fatalf("cleanup selected the wrong Firebase account")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if doc, err := read[Account](ctx, nil, s.doc("verified_accounts", docID(*account.AccountID))); err != nil || doc != nil {
		t.Fatalf("account tombstone remains: %v", err)
	}
	snapshot, err := s.Quota(ctx, other.Account.ID, false)
	if err != nil || snapshot.Used != 1 {
		t.Fatalf("shared usage after account deletion: %d (%v)", snapshot.Used, err)
	}
}
