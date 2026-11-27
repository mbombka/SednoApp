package store

import (
	"context"
	"errors"
	"slices"
	"time"

	"cloud.google.com/go/firestore"
)

type Identity struct {
	Id               string
	InstallationHash string
	CreatedAt        time.Time
	AccountId        *string
}

type Account struct {
	Id                    string
	TesterAccessExpiresAt *time.Time
	InstallationHashes    []string
	Deleting              bool
	FirebaseUid           string
	Provider              string
	PrimaryIdentityId     string
	CreatedAt             time.Time
}

type reservation struct {
	IdentityId string
	ExpiresAt  time.Time
}

type ledger struct {
	InstallationHash string
	Day              string
	ExpiresAt        time.Time
	Used             map[string]int
	Reservations     map[string]reservation
}

func (l *ledger) expire(now time.Time) {
	for id, r := range l.Reservations {
		if !r.ExpiresAt.After(now) {
			delete(l.Reservations, id)
		}
	}
}

type record struct {
	IdentityId           string
	RequestId            string
	Fingerprint          string
	State                requestState
	CreatedAt            time.Time
	ReservationDay       string
	ReservationExpiresAt time.Time
	FinishedAt           *time.Time
}

type requestState int

const (
	processing requestState = iota
	succeeded
	failed
	expired
)

type Quota struct {
	Tier                  string     `json:"tier"`
	Limit                 int        `json:"limit"`
	Used                  int        `json:"used"`
	Remaining             int        `json:"remaining"`
	ServerTime            time.Time  `json:"serverTime"`
	ResetAt               time.Time  `json:"resetAt"`
	TesterAccessExpiresAt *time.Time `json:"testerAccessExpiresAt"`
}

type RequestStatus struct {
	RequestID      string     `json:"requestId"`
	Status         string     `json:"status"`
	ReservationDay time.Time  `json:"reservationDay"`
	FinishedAt     *time.Time `json:"finishedAt"`
	Quota          Quota      `json:"quota"`
}

func (s *Store) request(id, requestID string) *firestore.DocumentRef {
	return s.doc("simplification_requests", docID(id)+"_"+requestID)
}

func (s *Store) dayLedger(installation, day string) *firestore.DocumentRef {
	return s.doc("daily_usage", installation+"_"+day)
}

func (s *Store) identity(ctx context.Context, tx *firestore.Transaction, id string) (*Identity, error) {
	value, err := read[Identity](ctx, tx, s.doc("guest_identities", docID(id)))
	if err == nil && value == nil {
		return nil, errors.New("identity unavailable")
	}
	return value, err
}

func (s *Store) active(ctx context.Context, tx *firestore.Transaction, id string) (*Identity, *Account, error) {
	identity, err := s.identity(ctx, tx, id)
	if err != nil || identity.AccountId == nil {
		return identity, nil, err
	}
	account, err := read[Account](ctx, tx, s.doc("verified_accounts", docID(*identity.AccountId)))
	if err == nil && (account == nil || account.Deleting) {
		err = errors.New("account unavailable")
	}
	return identity, account, err
}

type usageSnapshot struct {
	identity *Identity
	days     map[string]*ledger
	quota    Quota
}

func (s *Store) snapshot(ctx context.Context, tx *firestore.Transaction, id string, paid bool, now time.Time) (usageSnapshot, error) {
	identity, account, err := s.active(ctx, tx, id)
	if err != nil {
		return usageSnapshot{}, err
	}
	hashes := []string{identity.InstallationHash}
	quota := Quota{Tier: "free", Limit: 5, ServerTime: now, ResetAt: now.Truncate(24*time.Hour).AddDate(0, 0, 1)}
	if account != nil {
		hashes = append(hashes, account.InstallationHashes...)
		quota.TesterAccessExpiresAt = account.TesterAccessExpiresAt
		if quota.TesterAccessExpiresAt != nil && quota.TesterAccessExpiresAt.After(now) {
			quota.Tier, quota.Limit = "tester", 400
		}
		if paid {
			quota.Tier, quota.Limit = "subscription", 400
		}
	}
	slices.Sort(hashes)
	days := make(map[string]*ledger)
	day := now.Format(time.DateOnly)
	reserved := 0
	for _, hash := range slices.Compact(hashes) {
		usage, err := read[ledger](ctx, tx, s.dayLedger(hash, day))
		if err != nil {
			return usageSnapshot{}, err
		}
		if usage == nil {
			usage = &ledger{InstallationHash: hash, Day: day, ExpiresAt: now.Truncate(24*time.Hour).AddDate(0, 0, 8)}
		}
		usage.expire(now)
		for _, used := range usage.Used {
			quota.Used += used
		}
		reserved += len(usage.Reservations)
		days[hash] = usage
	}
	quota.Remaining = max(0, quota.Limit-quota.Used-reserved)
	return usageSnapshot{identity, days, quota}, nil
}

func (s *Store) Quota(ctx context.Context, id string, paid bool) (Quota, error) {
	var snapshot usageSnapshot
	err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		var err error
		snapshot, err = s.snapshot(ctx, tx, id, paid, s.now())
		return err
	}, firestore.ReadOnly, firestore.MaxAttempts(10))
	return snapshot.quota, err
}

func (s *Store) withUsageLease(ctx context.Context, id string, run func(context.Context, *firestore.Transaction) error) error {
	identity, err := s.identity(ctx, nil, id)
	if err != nil {
		return err
	}
	lock, err := s.acquire(ctx, "usage:"+identity.InstallationHash)
	if err != nil {
		return err
	}
	defer lock.release()
	return s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		if err := lock.check(ctx, tx); err != nil {
			return err
		}
		return run(ctx, tx)
	}, firestore.MaxAttempts(10))
}

func (s *Store) Reserve(ctx context.Context, id, requestID, fingerprint string, paid bool) (string, Quota, error) {
	var kind string
	var quota Quota
	err := s.withUsageLease(ctx, id, func(ctx context.Context, tx *firestore.Transaction) error {
		now := s.now()
		snapshot, err := s.snapshot(ctx, tx, id, paid, now)
		if err != nil {
			return err
		}
		quota = snapshot.quota
		ref := s.request(id, requestID)
		previous, err := read[record](ctx, tx, ref)
		if err != nil {
			return err
		}
		if previous != nil {
			if previous.State == processing && !previous.ReservationExpiresAt.After(now) {
				previous.State, previous.FinishedAt = expired, &now
				if err := tx.Set(ref, previous); err != nil {
					return err
				}
			}
			switch {
			case previous.Fingerprint != fingerprint:
				kind = "key_conflict"
			case previous.State == processing:
				kind = "processing"
			case previous.State == succeeded:
				kind = "result_unavailable"
			case previous.State == expired:
				kind = "expired"
			default:
				kind = "failed"
			}
			return nil
		}
		if quota.Remaining == 0 {
			kind = "quota_exceeded"
			return nil
		}
		day := now.Format(time.DateOnly)
		hash := snapshot.identity.InstallationHash
		usage := snapshot.days[hash]
		if usage.Reservations == nil {
			usage.Reservations = make(map[string]reservation)
		}
		if usage.Used == nil {
			usage.Used = make(map[string]int)
		}
		until := now.Add(5 * time.Minute)
		usage.Reservations[ref.ID] = reservation{id, until}
		kind = "reserved"
		quota.Remaining--
		if err := tx.Set(s.dayLedger(hash, day), usage); err != nil {
			return err
		}
		return tx.Create(ref, record{IdentityId: id, RequestId: requestID, Fingerprint: fingerprint, State: processing,
			CreatedAt: now, ReservationDay: day, ReservationExpiresAt: until})
	})
	return kind, quota, err
}

func (s *Store) Finish(ctx context.Context, id, requestID string, success bool) (bool, error) {
	ref := s.request(id, requestID)
	hint, err := read[record](ctx, nil, ref)
	if err != nil || hint == nil {
		return false, err
	}
	var completed bool
	err = s.withUsageLease(ctx, id, func(ctx context.Context, tx *firestore.Transaction) error {
		completed = false
		now := s.now()
		identity, _, err := s.active(ctx, tx, id)
		if err != nil {
			return err
		}
		dayRef := s.dayLedger(identity.InstallationHash, hint.ReservationDay)
		usage, err := read[ledger](ctx, tx, dayRef)
		if err != nil || usage == nil {
			return err
		}
		current, err := read[record](ctx, tx, ref)
		if err != nil || current == nil || current.State != processing || current.ReservationDay != hint.ReservationDay {
			return err
		}
		usage.expire(now)
		delete(usage.Reservations, ref.ID)
		current.State, current.FinishedAt = failed, &now
		if success {
			current.State = expired
			if current.ReservationExpiresAt.After(now) {
				completed, current.State = true, succeeded
				if usage.Used == nil {
					usage.Used = make(map[string]int)
				}
				usage.Used[docID(id)]++
			}
		}
		if err := tx.Set(dayRef, usage); err != nil {
			return err
		}
		return tx.Set(ref, current)
	})
	return completed, err
}

func (s *Store) Status(ctx context.Context, id, requestID string, paid bool) (*RequestStatus, error) {
	var result *RequestStatus
	err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		now := s.now()
		snapshot, err := s.snapshot(ctx, tx, id, paid, now)
		if err != nil {
			return err
		}
		current, err := read[record](ctx, tx, s.request(id, requestID))
		if err != nil || current == nil {
			return err
		}
		if current.State == processing && !current.ReservationExpiresAt.After(now) {
			current.State, current.FinishedAt = expired, &now
		}
		reservationDay, err := time.Parse(time.DateOnly, current.ReservationDay)
		if err != nil {
			return err
		}
		names := [...]string{"processing", "succeeded", "failed", "expired"}
		if current.State < 0 || int(current.State) >= len(names) {
			return errors.New("invalid request state")
		}
		result = &RequestStatus{current.RequestId, names[current.State], reservationDay, current.FinishedAt, snapshot.quota}
		return nil
	}, firestore.ReadOnly, firestore.MaxAttempts(10))
	return result, err
}

func (s *Store) AccountQuota(ctx context.Context, accountID string) (Quota, error) {
	account, err := read[Account](ctx, nil, s.doc("verified_accounts", docID(accountID)))
	if err != nil {
		return Quota{}, err
	}
	if account == nil || account.Deleting {
		return Quota{}, errors.New("account unavailable")
	}
	return s.Quota(ctx, account.PrimaryIdentityId, true)
}
