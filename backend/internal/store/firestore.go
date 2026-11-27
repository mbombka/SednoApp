package store

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"strings"
	"time"

	"cloud.google.com/go/firestore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type Store struct {
	DB               *firestore.Client
	Now              func() time.Time
	RequireMigration bool
}

func (s *Store) now() time.Time { return s.Now().UTC() }

func (s *Store) doc(collection, id string) *firestore.DocumentRef {
	return s.DB.Collection(collection).Doc(id)
}

func docID(id string) string { return strings.ToLower(strings.ReplaceAll(id, "-", "")) }

func hash(value string) string {
	sum := sha256.Sum256([]byte(value))
	return strings.ToUpper(hex.EncodeToString(sum[:]))
}

func read[T any](ctx context.Context, tx *firestore.Transaction, ref *firestore.DocumentRef) (*T, error) {
	var snapshot *firestore.DocumentSnapshot
	var err error
	if tx != nil {
		snapshot, err = tx.Get(ref)
	} else {
		snapshot, err = ref.Get(ctx)
	}
	if status.Code(err) == codes.NotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	var value T
	if err := snapshot.DataTo(&value); err != nil {
		return nil, err
	}
	return &value, nil
}

func (s *Store) Ready(ctx context.Context) bool {
	var ref = s.doc("system", "migration")
	marker, err := ref.Get(ctx)
	if status.Code(err) == codes.NotFound {
		return !s.RequireMigration
	}
	if err != nil {
		return false
	}
	inProgress, ok := marker.Data()["InProgress"].(bool)
	return ok && !inProgress
}

type leaseDocument struct {
	Owner     string
	ExpiresAt time.Time
}

type lease struct {
	store *Store
	ref   *firestore.DocumentRef
	owner string
}

func (s *Store) acquire(ctx context.Context, scope string) (*lease, error) {
	ref := s.doc("operation_leases", hash(scope))
	owner := docID(newID())
	newValue := func() leaseDocument { return leaseDocument{owner, s.now().Add(2 * time.Minute)} }
	for ctx.Err() == nil {
		if _, err := ref.Create(ctx, newValue()); err == nil {
			return &lease{s, ref, owner}, nil
		} else if status.Code(err) != codes.AlreadyExists {
			return nil, err
		}
		current, err := read[leaseDocument](ctx, nil, ref)
		if err != nil {
			return nil, err
		}
		if current == nil {
			continue
		}
		if !current.ExpiresAt.After(s.now()) {
			var acquired bool
			err := s.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
				value, err := read[leaseDocument](ctx, tx, ref)
				acquired = err == nil && (value == nil || !value.ExpiresAt.After(s.now()))
				if !acquired {
					return err
				}
				return tx.Set(ref, newValue())
			})
			if err != nil {
				return nil, err
			}
			if acquired {
				return &lease{s, ref, owner}, nil
			}
		}
		timer := time.NewTimer(50 * time.Millisecond)
		select {
		case <-ctx.Done():
			timer.Stop()
		case <-timer.C:
		}
	}
	return nil, ctx.Err()
}

func (l *lease) check(ctx context.Context, tx *firestore.Transaction) error {
	current, err := read[leaseDocument](ctx, tx, l.ref)
	if err != nil {
		return err
	}
	if current == nil || current.Owner != l.owner || !current.ExpiresAt.After(l.store.now()) {
		return errors.New("operation lease expired")
	}
	return nil
}

func (l *lease) release() {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	// Keep failures from masking the operation outcome. A stale lease expires on its own.
	_ = l.store.DB.RunTransaction(ctx, func(ctx context.Context, tx *firestore.Transaction) error {
		current, err := read[leaseDocument](ctx, tx, l.ref)
		if err != nil || current == nil || current.Owner != l.owner {
			return err
		}
		return tx.Delete(l.ref)
	})
}
