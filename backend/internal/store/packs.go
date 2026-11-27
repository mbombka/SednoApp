package store

import (
	"context"
	"math"

	"cloud.google.com/go/firestore"
)

const PackProductID = "simplifications_1000"
const usesPerPack = 1000

type PlayPack struct {
	State, Product, Binding string
	Quantity                int
	Consumed                bool
}

type PlayPacks interface {
	LookupPack(context.Context, string) (PlayPack, error)
	ConsumePack(context.Context, string) error
}

type Packs struct {
	Store *Store
	Play  PlayPacks
}

type packReceipt struct {
	AccountId string `firestore:"AccountId,omitempty"`
	Quantity  int
	Revoked   bool
}

func (p *Packs) Verify(ctx context.Context, account, token string) (string, error) {
	lock, err := p.Store.acquire(ctx, "account:"+docID(account))
	if err != nil {
		return "", err
	}
	defer lock.release()

	status, err := p.Play.LookupPack(ctx, token)
	if err != nil {
		return "", err
	}
	if status.Product != PackProductID || status.Binding != binding(account) {
		return "invalid", nil
	}
	return p.apply(ctx, account, token, status, lock)
}

func (p *Packs) Notify(ctx context.Context, token string, fullRefund bool) error {
	ref := p.Store.doc("play_pack_purchases", hash(token))
	receipt, err := read[packReceipt](ctx, nil, ref)
	if err != nil {
		return err
	}
	if fullRefund && receipt == nil {
		// A refund can arrive before the original purchase is verified.
		err := p.Store.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
			var err error
			receipt, err = read[packReceipt](ctx, tx, ref)
			if err != nil || receipt != nil {
				return err
			}
			return tx.Create(ref, packReceipt{Revoked: true})
		})
		if err != nil || receipt == nil {
			return err
		}
	}
	if receipt != nil && receipt.Revoked {
		return nil
	}
	if fullRefund {
		lock, err := p.Store.acquire(ctx, "account:"+docID(receipt.AccountId))
		if err != nil {
			return err
		}
		defer lock.release()
		_, err = p.apply(ctx, receipt.AccountId, token, PlayPack{State: "CANCELLED"}, lock)
		return err
	}

	status, err := p.Play.LookupPack(ctx, token)
	if err != nil {
		return err
	}
	if status.Product != PackProductID || !validBinding(status.Binding) {
		return nil
	}
	ptr, err := read[accountPointer](ctx, nil, p.Store.doc("account_bindings", status.Binding))
	if err != nil || ptr == nil {
		return err
	}
	_, err = p.Verify(ctx, ptr.AccountId, token)
	return err
}

func (p *Packs) apply(ctx context.Context, account, token string, status PlayPack, lock *lease) (string, error) {
	switch status.State {
	case "PENDING":
		return "pending", nil
	case "PURCHASED", "CANCELLED":
	default:
		return "invalid", nil
	}
	quantity := status.Quantity
	if status.State == "CANCELLED" {
		quantity = 0
	}
	if quantity < 0 || quantity > math.MaxInt32/usesPerPack {
		return "invalid", nil
	}

	accountRef := p.Store.doc("verified_accounts", docID(account))
	ref := p.Store.doc("play_pack_purchases", hash(token))
	credited := false
	err := p.Store.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		credited = false
		if err := lock.check(ctx, tx); err != nil {
			return err
		}
		owner, err := read[Account](ctx, tx, accountRef)
		if err != nil || owner == nil || owner.Deleting {
			return err
		}
		receipt, err := read[packReceipt](ctx, tx, ref)
		if err != nil {
			return err
		}
		credits := quantity * usesPerPack
		if receipt != nil {
			if receipt.Revoked || receipt.AccountId != account {
				return nil
			}
			// Replays and stale snapshots cannot restore credits after a refund.
			if receipt.Quantity <= quantity {
				credited = receipt.Quantity > 0
				return nil
			}
			credits = owner.PackCredits[ref.ID] - (receipt.Quantity-quantity)*usesPerPack
		} else if quantity > 0 && status.Consumed {
			return nil
		}
		if credits > 0 {
			if owner.PackCredits == nil {
				owner.PackCredits = make(map[string]int)
			}
			owner.PackCredits[ref.ID] = credits
		} else {
			delete(owner.PackCredits, ref.ID)
		}
		if err := tx.Set(accountRef, owner); err != nil {
			return err
		}
		credited = quantity > 0
		return tx.Set(ref, packReceipt{AccountId: account, Quantity: quantity, Revoked: quantity == 0})
	})
	if err != nil {
		return "", err
	}
	if !credited {
		return "invalid", nil
	}
	// The committed receipt makes consumption safe to retry after transport failure.
	if !status.Consumed {
		if err := p.Play.ConsumePack(ctx, token); err != nil {
			return "", err
		}
	}
	return "credited", nil
}
