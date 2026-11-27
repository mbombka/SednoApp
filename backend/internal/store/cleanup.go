package store

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
)

// Cleanup follows the original retention periods and recovers pending account deletions.
func (s *Store) Cleanup(ctx context.Context, deleteIdentity func(context.Context, string) error) error {
	if !s.Ready(ctx) {
		return errors.New("Firestore migration must complete before cleanup")
	}
	now := s.now()
	accounts, err := s.DB.Collection("verified_accounts").Where("Deleting", "==", true).Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	for _, doc := range accounts {
		var account Account
		if err := doc.DataTo(&account); err != nil {
			return err
		}
		if err := s.deleteAccount(ctx, account.Id, deleteIdentity); err != nil {
			return err
		}
	}
	for _, query := range []firestore.Query{
		s.DB.Collection("simplification_requests").Where("CreatedAt", "<", now.AddDate(0, 0, -8)),
		s.DB.Collection("guest_sessions").Where("ExpiresAt", "<=", now),
		s.DB.Collection("daily_usage").Where("ExpiresAt", "<=", now),
		s.DB.Collection("operation_leases").Where("ExpiresAt", "<", now),
	} {
		if err := s.deleteQuery(ctx, query); err != nil {
			return err
		}
	}
	guests, err := s.DB.Collection("guest_identities").Where("CreatedAt", "<", now.AddDate(0, 0, -90)).Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	for _, doc := range guests {
		err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			identity, err := read[Identity](ctx, tx, doc.Ref)
			if err != nil || identity == nil || identity.AccountId != nil {
				return err
			}
			for _, collection := range []string{"guest_sessions", "simplification_requests"} {
				refs, err := tx.Documents(s.DB.Collection(collection).Where("IdentityId", "==", identity.Id).Limit(1)).GetAll()
				if err != nil || len(refs) != 0 {
					return err
				}
			}
			return tx.Delete(doc.Ref)
		})
		if err != nil {
			return err
		}
	}
	return nil
}

func (s *Store) deleteQuery(ctx context.Context, query firestore.Query) error {
	for {
		page, err := query.Limit(200).Documents(ctx).GetAll()
		if err != nil || len(page) == 0 {
			return err
		}
		batch := s.DB.Batch()
		for _, doc := range page {
			batch.Delete(doc.Ref, firestore.LastUpdateTime(doc.UpdateTime))
		}
		if _, err := batch.Commit(ctx); err != nil {
			return err
		}
	}
}

// DeleteAccount requires recent Firebase authentication and uncached revocation checks.
func (s *Store) DeleteAccount(ctx context.Context, session *Session, verified VerifiedIdentity, fresh AccountAccess, deleteIdentity func(context.Context, string) error) (bool, error) {
	if session == nil || session.AccountID == nil || fresh == nil || deleteIdentity == nil {
		return false, nil
	}
	now := s.now().Unix()
	if verified.AuthTime <= 0 || verified.AuthTime > now || verified.AuthTime < now-int64(5*time.Minute/time.Second) ||
		(verified.Provider != "google" && (verified.Provider != "email" || !verified.EmailVerified)) {
		return false, nil
	}
	account, err := read[Account](ctx, nil, s.doc("verified_accounts", docID(*session.AccountID)))
	if err != nil || account == nil || account.FirebaseUid != verified.UID {
		return false, err
	}
	credential, err := read[sessionDocument](ctx, nil, s.doc("guest_sessions", docID(session.ID)))
	if err != nil || credential == nil || credential.FirebaseAuthTime == nil || credential.AccountId == nil ||
		*credential.AccountId != account.Id || !credential.AccountAccessVerified || !credential.ExpiresAt.After(s.now()) {
		return false, err
	}
	for _, authTime := range []int64{*credential.FirebaseAuthTime, verified.AuthTime} {
		allowed, err := fresh(ctx, verified.UID, authTime)
		if err != nil || !allowed {
			return false, err
		}
	}
	err = s.deleteAccount(ctx, account.Id, deleteIdentity)
	return err == nil, err
}

func (s *Store) deleteAccount(ctx context.Context, accountID string, deleteIdentity func(context.Context, string) error) error {
	if deleteIdentity == nil {
		return errors.New("identity deletion is unavailable")
	}
	ref := s.doc("verified_accounts", docID(accountID))
	account, err := read[Account](ctx, nil, ref)
	if err != nil || account == nil {
		return err
	}
	uidLock, err := s.acquire(ctx, "uid:"+account.FirebaseUid)
	if err != nil {
		return err
	}
	defer uidLock.release()
	accountLock, err := s.acquire(ctx, "account:"+docID(accountID))
	if err != nil {
		return err
	}
	defer accountLock.release()
	check := func(ctx context.Context, tx *firestore.Transaction) error {
		if err := uidLock.check(ctx, tx); err != nil {
			return err
		}
		return accountLock.check(ctx, tx)
	}
	var deleting *Account
	err = s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		deleting = nil
		if err := check(ctx, tx); err != nil {
			return err
		}
		current, err := read[Account](ctx, tx, ref)
		if err != nil || current == nil {
			return err
		}
		if current.FirebaseUid != account.FirebaseUid {
			return errors.New("account owner changed")
		}
		current.Deleting = true
		deleting = current
		return tx.Set(ref, current)
	})
	if err != nil || deleting == nil {
		return err
	}
	// Persist the tombstone before Firebase I/O so a scheduled run can safely retry.
	if err := deleteIdentity(ctx, deleting.FirebaseUid); err != nil {
		return err
	}
	identities := s.DB.Collection("guest_identities").Where("AccountId", "==", accountID)
	docs, err := identities.Documents(ctx).GetAll()
	if err != nil {
		return err
	}
	ids := make(map[string]bool)
	for _, doc := range docs {
		var identity Identity
		if err := doc.DataTo(&identity); err != nil {
			return err
		}
		ids[docID(identity.Id)] = true
		for _, collection := range []string{"simplification_requests", "guest_sessions"} {
			if err := s.deleteQuery(ctx, s.DB.Collection(collection).Where("IdentityId", "==", identity.Id)); err != nil {
				return err
			}
		}
	}
	for _, collection := range []string{"guest_sessions", "play_purchases"} {
		if err := s.deleteQuery(ctx, s.DB.Collection(collection).Where("AccountId", "==", accountID)); err != nil {
			return err
		}
	}
	for _, installation := range deleting.InstallationHashes {
		days, err := s.DB.Collection("daily_usage").Where("InstallationHash", "==", installation).Documents(ctx).GetAll()
		if err != nil {
			return err
		}
		for _, doc := range days {
			if err := s.deleteUsage(ctx, doc.Ref, ids, check); err != nil {
				return err
			}
		}
	}
	if err := s.deleteQuery(ctx, identities); err != nil {
		return err
	}
	return s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := check(ctx, tx); err != nil {
			return err
		}
		for _, target := range []*firestore.DocumentRef{
			s.doc("firebase_uids", hash(deleting.FirebaseUid)),
			s.doc("account_bindings", hash("sedno-account:"+docID(accountID))),
			ref,
		} {
			if err := tx.Delete(target); err != nil {
				return err
			}
		}
		return nil
	})
}

func (s *Store) deleteUsage(ctx context.Context, ref *firestore.DocumentRef, ids map[string]bool, check func(context.Context, *firestore.Transaction) error) error {
	return s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := check(ctx, tx); err != nil {
			return err
		}
		usage, err := read[ledger](ctx, tx, ref)
		if err != nil || usage == nil {
			return err
		}
		for id := range ids {
			delete(usage.Used, id)
		}
		for key, reservation := range usage.Reservations {
			if ids[docID(reservation.IdentityId)] {
				delete(usage.Reservations, key)
			}
		}
		if len(usage.Used) == 0 && len(usage.Reservations) == 0 {
			return tx.Delete(ref)
		}
		return tx.Set(ref, usage)
	})
}
