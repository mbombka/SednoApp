package googleapi

import (
	"context"
	"crypto"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
	"unicode/utf16"

	"github.com/mbombka/SednoApp/backend/internal/store"
)

type Verifier struct {
	url      string
	audience string
	client   *http.Client
	mu       sync.Mutex
	keys     map[string]*rsa.PublicKey
	until    time.Time
}

func FirebaseVerifier(project string) *Verifier {
	return newVerifier("https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com", project)
}

func PubSubVerifier(audience string) *Verifier {
	return newVerifier("https://www.googleapis.com/oauth2/v1/certs", audience)
}

func newVerifier(endpoint, audience string) *Verifier {
	return &Verifier{url: endpoint, audience: audience, client: &http.Client{Timeout: 7 * time.Second, CheckRedirect: noRedirect}}
}

type claims struct {
	Audience      string `json:"aud"`
	Issuer        string `json:"iss"`
	Subject       string `json:"sub"`
	Expires       *int64 `json:"exp"`
	Issued        *int64 `json:"iat"`
	AuthTime      int64  `json:"auth_time"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Firebase      struct {
		Provider string `json:"sign_in_provider"`
	}
}

func (v *Verifier) Firebase(ctx context.Context, token string) *store.VerifiedIdentity {
	c := v.verify(ctx, token, "https://securetoken.google.com/"+v.audience)
	if c == nil || c.AuthTime <= 0 || c.AuthTime > time.Now().Unix() {
		return nil
	}
	var provider string
	switch c.Firebase.Provider {
	case "google.com":
		provider = "google"
	case "password":
		provider = "email"
	default:
		return nil
	}
	return &store.VerifiedIdentity{UID: c.Subject, Provider: provider, EmailVerified: c.EmailVerified, AuthTime: c.AuthTime}
}

func (v *Verifier) PubSub(ctx context.Context, token, email string) bool {
	c := v.verify(ctx, token, "https://accounts.google.com", "accounts.google.com")
	return c != nil && c.EmailVerified && c.Email == email
}

func (v *Verifier) verify(ctx context.Context, token string, issuers ...string) *claims {
	if len(token) == 0 || len(token) > 8192 {
		return nil
	}
	pieces := strings.Split(token, ".")
	if len(pieces) != 3 {
		return nil
	}
	var header struct {
		Alg string
		Kid string
	}
	var c claims
	if !decodePart(pieces[0], &header) || !decodePart(pieces[1], &c) ||
		header.Alg != "RS256" || header.Kid == "" || c.Audience != v.audience ||
		c.Subject == "" || len(utf16.Encode([]rune(c.Subject))) > 128 ||
		c.Expires == nil || c.Issued == nil {
		return nil
	}
	now := time.Now().Unix()
	if *c.Expires <= now || *c.Issued > now {
		return nil
	}
	if c.Issuer != issuers[0] && (len(issuers) < 2 || c.Issuer != issuers[1]) {
		return nil
	}
	signature, err := base64.RawURLEncoding.DecodeString(pieces[2])
	if err != nil {
		return nil
	}
	key := v.key(ctx, header.Kid)
	if key == nil {
		return nil
	}
	hash := sha256.Sum256([]byte(pieces[0] + "." + pieces[1]))
	if rsa.VerifyPKCS1v15(key, crypto.SHA256, hash[:], signature) != nil {
		return nil
	}
	return &c
}

func decodePart(part string, dst any) bool {
	raw, err := base64.RawURLEncoding.DecodeString(part)
	return err == nil && json.Unmarshal(raw, dst) == nil
}

func (v *Verifier) key(ctx context.Context, id string) *rsa.PublicKey {
	v.mu.Lock()
	defer v.mu.Unlock()
	if time.Now().Before(v.until) {
		return v.keys[id]
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, v.url, nil)
	if err != nil {
		return nil
	}
	resp, err := v.client.Do(req)
	if err != nil {
		return nil
	}
	defer resp.Body.Close()
	var certificates map[string]string
	if resp.StatusCode != 200 || decode(resp.Body, &certificates, 256<<10) != nil {
		return nil
	}
	keys := make(map[string]*rsa.PublicKey, len(certificates))
	for id, value := range certificates {
		block, _ := pem.Decode([]byte(value))
		if block == nil {
			continue
		}
		cert, err := x509.ParseCertificate(block.Bytes)
		if err == nil {
			if key, ok := cert.PublicKey.(*rsa.PublicKey); ok {
				keys[id] = key
			}
		}
	}
	if len(keys) == 0 {
		return nil
	}
	ttl := 5 * time.Minute
	for age := range strings.SplitSeq(resp.Header.Get("Cache-Control"), ",") {
		if value, ok := strings.CutPrefix(strings.TrimSpace(age), "max-age="); ok {
			if seconds, err := strconv.ParseUint(value, 10, 32); err == nil {
				ttl = min(24*time.Hour, time.Duration(seconds)*time.Second)
			}
		}
	}
	v.keys, v.until = keys, time.Now().Add(ttl)
	return keys[id]
}
