package store

import (
	"context"
	"errors"
	"time"

	"cloud.google.com/go/firestore"
)

type PlaySubscription struct {
	State                string
	ExpiresAt            *time.Time
	Acknowledged         bool
	Binding, LinkedToken string
}

func (p PlaySubscription) entitled(now time.Time) bool {
	if p.ExpiresAt == nil || !p.ExpiresAt.After(now) {
		return false
	}
	switch p.State {
	case "SUBSCRIPTION_STATE_ACTIVE", "SUBSCRIPTION_STATE_IN_GRACE_PERIOD", "SUBSCRIPTION_STATE_CANCELED":
		return true
	default:
		return false
	}
}

type PlayBilling interface {
	Lookup(context.Context, string) (PlaySubscription, error)
	Acknowledge(context.Context, string) error
}
type PurchaseProtection interface {
	Protect(string) (string, error)
	Unprotect(string) (string, error)
}
type Billing struct {
	Store      *Store
	Play       PlayBilling
	Protection PurchaseProtection
}
type purchase struct {
	TokenHash, ProtectedToken, AccountId, State string
	ExpiresAt                                   *time.Time
	Revoked                                     bool
	VerifiedAt, RefreshNotBefore                *time.Time
}
type notification struct {
	Id          string
	ProcessedAt time.Time
}
type Subscription struct {
	State                string     `json:"state"`
	Active               bool       `json:"active"`
	ExpiresAt            *time.Time `json:"expiresAt"`
	AccountBinding       string     `json:"accountBinding"`
	PackPurchasesEnabled bool       `json:"packPurchasesEnabled"`
}

func binding(account string) string { return hash("sedno-account:" + docID(account)) }

func (b *Billing) purchases(ctx context.Context, account string) ([]purchase, error) {
	docs, err := b.Store.DB.Collection("play_purchases").Where("AccountId", "==", account).Where("Revoked", "==", false).Documents(ctx).GetAll()
	if err != nil {
		return nil, err
	}
	rows := make([]purchase, 0, len(docs))
	for _, doc := range docs {
		var row purchase
		if err := doc.DataTo(&row); err != nil {
			return nil, err
		}
		rows = append(rows, row)
	}
	return rows, nil
}

func fresh(row purchase, now time.Time) bool {
	return row.VerifiedAt != nil && !row.VerifiedAt.After(now) && row.VerifiedAt.After(now.Add(-15*time.Minute))
}

func refreshNeeded(row purchase, now time.Time) bool {
	return !row.Revoked && !fresh(row, now) && (row.RefreshNotBefore == nil || !row.RefreshNotBefore.After(now))
}

func entitled(rows []purchase, now time.Time) bool {
	for _, row := range rows {
		if !row.Revoked && fresh(row, now) && (PlaySubscription{State: row.State, ExpiresAt: row.ExpiresAt}).entitled(now) {
			return true
		}
	}
	return false
}

func (b *Billing) Paid(ctx context.Context, account *string) (bool, error) {
	if account == nil {
		return false, nil
	}
	rows, err := b.purchases(ctx, *account)
	if err != nil {
		return false, err
	}
	now := b.Store.now()
	if entitled(rows, now) {
		return true, nil
	}
	for _, row := range rows {
		if refreshNeeded(row, now) {
			return b.refresh(ctx, *account)
		}
	}
	return false, nil
}

func (b *Billing) refresh(ctx context.Context, account string) (bool, error) {
	lock, err := b.Store.acquire(ctx, "account:"+docID(account))
	if err != nil {
		return false, err
	}
	defer lock.release()
	rows, err := b.purchases(ctx, account)
	if err != nil {
		return false, err
	}
	if entitled(rows, b.Store.now()) {
		return true, nil
	}
	for _, row := range rows {
		if !refreshNeeded(row, b.Store.now()) {
			continue
		}
		refreshCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
		token, err := b.Protection.Unprotect(row.ProtectedToken)
		var subscription Subscription
		if err == nil {
			subscription, err = b.update(refreshCtx, account, token, lock, "")
		}
		cancel()
		if err != nil {
			if err := b.refreshCooldown(account, row.TokenHash, lock); err != nil {
				return false, err
			}
			if ctx.Err() != nil {
				return false, ctx.Err()
			}
		} else if subscription.Active {
			return true, nil
		}
	}
	return false, nil
}

func (b *Billing) refreshCooldown(account, tokenHash string, lock *lease) error {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	ref := b.Store.doc("play_purchases", tokenHash)
	return b.Store.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := lock.check(ctx, tx); err != nil {
			return err
		}
		row, err := read[purchase](ctx, tx, ref)
		now := b.Store.now()
		if err != nil || row == nil || row.AccountId != account || row.Revoked || fresh(*row, now) {
			return err
		}
		next := now.Add(time.Minute)
		row.RefreshNotBefore = &next
		return tx.Set(ref, row)
	})
}

func (b *Billing) Current(ctx context.Context, account string) (Subscription, error) {
	lock, err := b.Store.acquire(ctx, "account:"+docID(account))
	if err != nil {
		return Subscription{}, err
	}
	defer lock.release()
	rows, err := b.purchases(ctx, account)
	if err != nil {
		return Subscription{}, err
	}
	best := Subscription{State: "none", AccountBinding: binding(account)}
	for i, row := range rows {
		token, err := b.Protection.Unprotect(row.ProtectedToken)
		if err != nil {
			return Subscription{}, err
		}
		value, err := b.update(ctx, account, token, lock, "")
		if err != nil {
			return Subscription{}, err
		}
		if i == 0 || value.Active && !best.Active || value.Active == best.Active &&
			value.ExpiresAt != nil && best.ExpiresAt != nil && value.ExpiresAt.After(*best.ExpiresAt) {
			best = value
		}
	}
	return best, nil
}

func (b *Billing) Verify(ctx context.Context, account, token string) (Subscription, error) {
	lock, err := b.Store.acquire(ctx, "account:"+docID(account))
	if err != nil {
		return Subscription{}, err
	}
	defer lock.release()
	return b.update(ctx, account, token, lock, "")
}

func (b *Billing) Notify(ctx context.Context, id, token string) error {
	ref := b.Store.doc("play_notifications", hash(id))
	done, err := read[notification](ctx, nil, ref)
	if err != nil || done != nil {
		return err
	}
	row, err := read[purchase](ctx, nil, b.Store.doc("play_purchases", hash(token)))
	if err != nil {
		return err
	}
	var account string
	if row != nil {
		account = row.AccountId
	} else {
		status, err := b.Play.Lookup(ctx, token)
		if err != nil {
			return err
		}
		if status.Binding != "" && validBinding(status.Binding) {
			ptr, err := read[accountPointer](ctx, nil, b.Store.doc("account_bindings", status.Binding))
			if err != nil {
				return err
			}
			if ptr != nil {
				account = ptr.AccountId
			}
		}
	}
	if account == "" {
		return errors.New("unknown purchase owner")
	}
	lock, err := b.Store.acquire(ctx, "account:"+docID(account))
	if err != nil {
		return err
	}
	defer lock.release()
	done, err = read[notification](ctx, nil, ref)
	if err != nil || done != nil {
		return err
	}
	_, err = b.update(ctx, account, token, lock, id)
	return err
}

func validBinding(value string) bool {
	if len(value) != 64 {
		return false
	}
	for _, c := range value {
		if !(c >= '0' && c <= '9' || c >= 'A' && c <= 'F') {
			return false
		}
	}
	return true
}

func (b *Billing) update(ctx context.Context, account, token string, lock *lease, message string) (Subscription, error) {
	accountRef := b.Store.doc("verified_accounts", docID(account))
	readAccount := func(ctx context.Context, tx *firestore.Transaction) error {
		current, err := read[Account](ctx, tx, accountRef)
		if err == nil && (current == nil || current.Deleting) {
			return errors.New("account unavailable")
		}
		return err
	}
	if err := readAccount(ctx, nil); err != nil {
		return Subscription{}, err
	}
	status, err := b.Play.Lookup(ctx, token)
	if err != nil {
		return Subscription{}, err
	}
	now := b.Store.now()
	ref := b.Store.doc("play_purchases", hash(token))
	accountBinding := binding(account)
	validate := func(row *purchase) error {
		if status.Binding != accountBinding && !(status.Binding == "" && status.State == "SUBSCRIPTION_STATE_EXPIRED" && row != nil && row.AccountId == account) ||
			row != nil && row.AccountId != account {
			return errors.New("purchase owner mismatch")
		}
		return nil
	}
	existing, err := read[purchase](ctx, nil, ref)
	if err != nil {
		return Subscription{}, err
	}
	if err := validate(existing); err != nil {
		return Subscription{}, err
	}
	if (existing == nil || !existing.Revoked) && status.entitled(b.Store.now()) && !status.Acknowledged {
		if err := b.Play.Acknowledge(ctx, token); err != nil {
			return Subscription{}, err
		}
	}
	var result Subscription
	err = b.Store.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := lock.check(ctx, tx); err != nil {
			return err
		}
		if err := readAccount(ctx, tx); err != nil {
			return err
		}
		row, err := read[purchase](ctx, tx, ref)
		if err != nil {
			return err
		}
		if err := validate(row); err != nil {
			return err
		}
		active := status.entitled(b.Store.now())
		if status.LinkedToken != "" && status.LinkedToken != token && active {
			oldRef := b.Store.doc("play_purchases", hash(status.LinkedToken))
			old, err := read[purchase](ctx, tx, oldRef)
			if err != nil {
				return err
			}
			if old != nil {
				if old.AccountId != account {
					return errors.New("linked purchase owner mismatch")
				}
				old.Revoked = true
				if err := tx.Set(oldRef, old); err != nil {
					return err
				}
			}
		}
		if row == nil {
			protected, err := b.Protection.Protect(token)
			if err != nil {
				return err
			}
			row = &purchase{TokenHash: ref.ID, ProtectedToken: protected, AccountId: account}
		}
		row.State, row.ExpiresAt, row.VerifiedAt, row.RefreshNotBefore = status.State, status.ExpiresAt, &now, nil
		if err := tx.Set(ref, row); err != nil {
			return err
		}
		if message != "" {
			if err := tx.Create(b.Store.doc("play_notifications", hash(message)), notification{message, b.Store.now()}); err != nil {
				return err
			}
		}
		state := status.State
		if row.Revoked {
			state = "revoked"
		}
		result = Subscription{State: state, Active: !row.Revoked && active, ExpiresAt: status.ExpiresAt, AccountBinding: accountBinding}
		return nil
	})
	return result, err
}
