package store

import (
	"context"
	"crypto/hmac"
	"crypto/rand"
	"encoding/base64"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/mbombka/SednoApp/backend/internal/simplification"
)

func newID() string { return uuid.NewString() }

type sessionDocument struct {
	Id                    string
	IdentityId            string
	Identity              *Identity
	AccountId             *string
	CredentialHash        string
	CreatedAt             time.Time
	ExpiresAt             time.Time
	AccountAccessVerified bool
	FirebaseAuthTime      *int64
}

type Session struct {
	ID         string
	IdentityID string
	AccountID  *string
}

type SessionResponse struct {
	AccessToken string         `json:"accessToken"`
	Account     SessionAccount `json:"account"`
	Quota       Quota          `json:"quota"`
}

type SessionAccount struct {
	ID       string `json:"id"`
	Provider string `json:"provider"`
}

func (s *Store) CreateGuest(ctx context.Context, installation string, key []byte) (SessionResponse, error) {
	now := s.now()
	identity := Identity{Id: newID(), CreatedAt: now, InstallationHash: simplification.HMAC(key, installation)}
	secret := newSecret()
	session := sessionDocument{
		Id: newID(), IdentityId: identity.Id, CreatedAt: now, ExpiresAt: now.AddDate(0, 0, 90),
		CredentialHash: credentialHash(key, secret),
	}
	batch := s.DB.Batch()
	batch.Create(s.doc("guest_identities", docID(identity.Id)), identity)
	batch.Create(s.doc("guest_sessions", docID(session.Id)), session)
	if _, err := batch.Commit(ctx); err != nil {
		return SessionResponse{}, err
	}
	quota, err := s.Quota(ctx, identity.Id, false)
	return SessionResponse{docID(session.Id) + "." + secret, SessionAccount{identity.Id, "guest"}, quota}, err
}

func newSecret() string {
	var random [32]byte
	rand.Read(random[:])
	return base64.RawURLEncoding.EncodeToString(random[:])
}

type AccountAccess func(context.Context, string, int64) (bool, error)

func (s *Store) Authenticate(ctx context.Context, credential string, key []byte, allow AccountAccess) (*Session, error) {
	id, secret, ok := strings.Cut(credential, ".")
	if !ok || len(id) != 32 || len(secret) != 43 {
		return nil, nil
	}
	if _, err := uuid.Parse(id); err != nil {
		return nil, nil
	}
	session, err := read[sessionDocument](ctx, nil, s.doc("guest_sessions", strings.ToLower(id)))
	if err != nil || session == nil || !session.ExpiresAt.After(s.now()) {
		return nil, err
	}
	if !hmac.Equal([]byte(session.CredentialHash), []byte(credentialHash(key, secret))) {
		return nil, nil
	}
	identity, err := read[Identity](ctx, nil, s.doc("guest_identities", docID(session.IdentityId)))
	if err != nil || identity == nil {
		return nil, err
	}
	if session.AccountId == nil {
		if identity.AccountId != nil {
			return nil, nil
		}
		return &Session{session.Id, identity.Id, nil}, nil
	}
	if allow == nil || !session.AccountAccessVerified || session.FirebaseAuthTime == nil {
		return nil, nil
	}
	account, err := read[Account](ctx, nil, s.doc("verified_accounts", docID(*session.AccountId)))
	if err != nil || account == nil || account.Deleting {
		return nil, err
	}
	if allowed, err := allow(ctx, account.FirebaseUid, *session.FirebaseAuthTime); err != nil || !allowed {
		return nil, err
	}
	return &Session{session.Id, account.PrimaryIdentityId, &account.Id}, nil
}

func (s *Store) SignOut(ctx context.Context, session *Session) error {
	_, err := s.doc("guest_sessions", docID(session.ID)).Delete(ctx)
	return err
}

func credentialHash(key []byte, secret string) string {
	return simplification.HMAC(key, secret)
}
