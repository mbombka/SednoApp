package store

import (
	"context"
	"slices"
	"time"
	"unicode/utf16"

	"cloud.google.com/go/firestore"
)

type VerifiedIdentity struct {
	UID           string
	Provider      string
	EmailVerified bool
	AuthTime      int64
}

type accountPointer struct {
	AccountId string
}

// Link verifies current Firebase account access while holding the UID lease.
// The Firestore transaction alone changes ownership and exchanges credentials.
func (s *Store) Link(ctx context.Context, guest *Session, verified VerifiedIdentity, key []byte, fresh AccountAccess) (*SessionResponse, error) {
	if guest == nil || guest.AccountID != nil || fresh == nil || verified.AuthTime <= 0 ||
		verified.UID == "" || len(utf16.Encode([]rune(verified.UID))) > 128 ||
		(verified.Provider != "google" && (verified.Provider != "email" || !verified.EmailVerified)) {
		return nil, nil
	}
	lock, err := s.acquire(ctx, "uid:"+verified.UID)
	if err != nil {
		return nil, err
	}
	defer lock.release()
	allowed, err := fresh(ctx, verified.UID, verified.AuthTime)
	if err != nil || !allowed {
		return nil, err
	}
	account, session, secret, err := s.linkTransaction(ctx, lock, guest, verified, key)
	if err != nil || account == nil {
		return nil, err
	}
	quota, err := s.Quota(ctx, account.PrimaryIdentityId, false)
	if err != nil {
		return nil, err
	}
	return &SessionResponse{docID(session) + "." + secret, SessionAccount{account.Id, account.Provider}, quota}, nil
}

func (s *Store) linkTransaction(ctx context.Context, lock *lease, guest *Session, verified VerifiedIdentity, key []byte) (*Account, string, string, error) {
	var result *Account
	accountID, sessionID, secret := newID(), newID(), newSecret()
	identityRef := s.doc("guest_identities", docID(guest.IdentityID))
	guestRef := s.doc("guest_sessions", docID(guest.ID))
	pointerRef := s.doc("firebase_uids", hash(verified.UID))
	err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		result = nil
		if err := lock.check(ctx, tx); err != nil {
			return err
		}
		identity, err := read[Identity](ctx, tx, identityRef)
		if err != nil || identity == nil {
			return err
		}
		original, err := read[sessionDocument](ctx, tx, guestRef)
		now := s.now()
		if err != nil || original == nil || original.IdentityId != guest.IdentityID || original.AccountId != nil || !original.ExpiresAt.After(now) {
			return err
		}
		pointer, err := read[accountPointer](ctx, tx, pointerRef)
		if err != nil {
			return err
		}
		selectedID := accountID
		if pointer != nil {
			selectedID = pointer.AccountId
		}
		accountRef := s.doc("verified_accounts", docID(selectedID))
		account, err := read[Account](ctx, tx, accountRef)
		if err != nil || pointer != nil && account == nil {
			return err
		}
		if account == nil {
			account = &Account{Id: accountID, FirebaseUid: verified.UID, PrimaryIdentityId: identity.Id, CreatedAt: now}
		}
		if account.Deleting || account.FirebaseUid != verified.UID || (identity.AccountId != nil && *identity.AccountId != account.Id) {
			return nil
		}
		oldSessions, err := tx.Documents(s.DB.Collection("guest_sessions").
			Where("IdentityId", "==", identity.Id).Where("AccountId", "==", nil)).GetAll()
		if err != nil {
			return err
		}
		account.Provider = verified.Provider
		if !slices.Contains(account.InstallationHashes, identity.InstallationHash) {
			account.InstallationHashes = append(account.InstallationHashes, identity.InstallationHash)
		}
		identity.AccountId = &account.Id
		for _, pair := range []struct {
			ref   *firestore.DocumentRef
			value any
		}{
			{identityRef, identity},
			{accountRef, account},
			{pointerRef, accountPointer{account.Id}},
			{s.doc("account_bindings", hash("sedno-account:"+docID(account.Id))), accountPointer{account.Id}},
		} {
			if err := tx.Set(pair.ref, pair.value); err != nil {
				return err
			}
		}
		for _, old := range oldSessions {
			if err := tx.Delete(old.Ref); err != nil {
				return err
			}
		}
		if err := tx.Create(s.doc("guest_sessions", docID(sessionID)), sessionDocument{
			Id: sessionID, IdentityId: account.PrimaryIdentityId, AccountId: &account.Id,
			CredentialHash: credentialHash(key, secret), CreatedAt: now, ExpiresAt: now.Add(7 * 24 * time.Hour),
			AccountAccessVerified: true, FirebaseAuthTime: &verified.AuthTime,
		}); err != nil {
			return err
		}
		result = account
		return nil
	})
	return result, sessionID, secret, err
}
