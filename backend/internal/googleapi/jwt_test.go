package googleapi

import (
	"context"
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"testing"
	"time"
)

func TestGoogleTokenBoundaries(t *testing.T) {
	signingKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	now := time.Now().Unix()
	firebase := FirebaseVerifier("demo-sedno")
	push := PubSubVerifier("https://staging.example/notifications/google-play")
	for _, verifier := range []*Verifier{firebase, push} {
		verifier.keys = map[string]*rsa.PublicKey{"synthetic": &signingKey.PublicKey}
		verifier.until = time.Now().Add(time.Hour)
	}
	encode := func(value any) string {
		data, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		return base64.RawURLEncoding.EncodeToString(data)
	}
	sign := func(header, payload map[string]any) string {
		data := encode(header) + "." + encode(payload)
		hash := sha256.Sum256([]byte(data))
		signature, err := rsa.SignPKCS1v15(rand.Reader, signingKey, crypto.SHA256, hash[:])
		if err != nil {
			t.Fatal(err)
		}
		return data + "." + base64.RawURLEncoding.EncodeToString(signature)
	}
	header := map[string]any{"alg": "RS256", "kid": "synthetic"}
	c := map[string]any{
		"iss": "https://securetoken.google.com/demo-sedno", "aud": "demo-sedno", "sub": "synthetic",
		"iat": now, "exp": now + 60, "auth_time": now, "email_verified": true,
		"firebase": map[string]string{"sign_in_provider": "password"},
	}
	good := sign(header, c)
	id := firebase.Firebase(ctx, good)
	if id == nil || id.Provider != "email" || !id.EmailVerified {
		t.Fatal("valid Firebase token rejected")
	}
	if firebase.Firebase(ctx, good+"x") != nil {
		t.Fatal("modified signature accepted")
	}
	for name, value := range map[string]any{"iss": "https://accounts.google.com", "aud": "different-project", "exp": now - 1, "iat": now + 60, "auth_time": now + 60} {
		original := c[name]
		c[name] = value
		if firebase.Firebase(ctx, sign(header, c)) != nil {
			t.Fatalf("accepted invalid %s", name)
		}
		c[name] = original
	}
	c["iss"], c["aud"], c["email"] = "accounts.google.com", push.audience, "pubsub@example.test"
	if !push.PubSub(ctx, sign(header, c), "pubsub@example.test") {
		t.Fatal("valid RTDN token rejected")
	}
	if push.PubSub(ctx, sign(header, c), "unexpected@example.test") {
		t.Fatal("RTDN accepted wrong service account")
	}
	c["email_verified"] = false
	if push.PubSub(ctx, sign(header, c), "pubsub@example.test") {
		t.Fatal("RTDN accepted unverified email")
	}
}
