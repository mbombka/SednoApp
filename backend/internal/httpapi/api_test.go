package httpapi

import (
	"context"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/mbombka/SednoApp/backend/internal/simplification"
	"github.com/mbombka/SednoApp/backend/internal/store"
)

func TestGuestFlowWithEmulator(t *testing.T) {
	address := os.Getenv("FIRESTORE_EMULATOR_HOST")
	if address == "" {
		t.Skip("Firestore emulator is required")
	}
	host, _, err := net.SplitHostPort(address)
	if err != nil || net.ParseIP(host) == nil || !net.ParseIP(host).IsLoopback() {
		t.Fatal("tests require a loopback emulator")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	db, err := firestore.NewClient(ctx, fmt.Sprintf("demo-sedno-go-%x", time.Now().UnixNano()))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	var calls atomic.Int32
	app := &API{
		Store:           &store.Store{DB: db, Now: time.Now},
		Development:     true,
		VerifyIntegrity: func(_ context.Context, _, token string) bool { return token == "development-ok" },
		CredentialKey:   make([]byte, 32),
		FingerprintKey:  make([]byte, 32),
		RunModel: func(_ context.Context, input simplification.Input) (string, error) {
			calls.Add(1)
			if input.RequestID == "fail" {
				return "", simplification.ErrProvider
			}
			return "synthetic output", nil
		},
	}
	authTime := time.Now().Unix()
	const uid = "synthetic-firebase-uid"
	app.VerifyIdentity = func(_ context.Context, token string) *store.VerifiedIdentity {
		switch token {
		case "unverified":
			return &store.VerifiedIdentity{UID: uid, Provider: "email", AuthTime: authTime}
		case "verified":
			return &store.VerifiedIdentity{UID: uid, Provider: "email", EmailVerified: true, AuthTime: authTime}
		case "other":
			return &store.VerifiedIdentity{UID: "other", Provider: "google", AuthTime: authTime}
		default:
			return nil
		}
	}
	app.AccountAccess = func(_ context.Context, user string, issued int64) (bool, error) {
		return user == uid && issued == authTime, nil
	}
	app.FreshAccountAccess = app.AccountAccess
	deleted := false
	app.DeleteIdentity = func(_ context.Context, user string) error {
		deleted = user == uid
		return nil
	}
	handler := app.Handler()
	request := func(method, path, body, token string) *httptest.ResponseRecorder {
		r := httptest.NewRequest(method, path, strings.NewReader(body)).WithContext(ctx)
		r.Header.Set("Content-Type", "application/json")
		if token != "" {
			r.Header.Set("Authorization", "Bearer "+token)
		}
		w := httptest.NewRecorder()
		handler.ServeHTTP(w, r)
		return w
	}
	check := func(response *httptest.ResponseRecorder, code int, body string) {
		t.Helper()
		if response.Code != code || !strings.Contains(response.Body.String(), body) || response.Header().Get("Cache-Control") != "no-store" {
			t.Fatalf("expected %d with %q and no-store, got %d %s", code, body, response.Code, response.Body)
		}
	}
	check(request("GET", "/health/ready", "", ""), 200, `"status":"ready"`)
	check(request("GET", "/v1/quota", "", ""), 401, "unauthorized")
	guest := func() string {
		w := request("POST", "/v1/guest-sessions", `{"installationId":"shared","integrityToken":"development-ok"}`, "")
		check(w, 200, `"provider":"guest"`)
		var result store.SessionResponse
		if err := json.Unmarshal(w.Body.Bytes(), &result); err != nil || result.AccessToken == "" {
			t.Fatal("invalid session response")
		}
		return result.AccessToken
	}
	first, second := guest(), guest()
	work := `{"requestId":"one","text":"synthetic input","language":"en-US","mode":"correct"}`
	var both sync.WaitGroup
	results := make(chan *httptest.ResponseRecorder, 2)
	for range 2 {
		both.Go(func() { results <- request("POST", "/v1/simplifications", work, first) })
	}
	both.Wait()
	close(results)
	success := 0
	for w := range results {
		switch w.Code {
		case 200:
			success++
			check(w, 200, `"language":"en-US"`)
		case 202:
			check(w, 202, "processing")
		case 409:
			check(w, 409, "result_unavailable")
		default:
			t.Fatalf("unexpected response %d %s", w.Code, w.Body)
		}
	}
	if calls.Load() != 1 || success != 1 {
		t.Fatalf("duplicate request had %d model calls and %d successes", calls.Load(), success)
	}
	check(request("POST", "/v1/simplifications", strings.Replace(work, "correct", "simplify", 1), first), 409, "key_conflict")
	check(request("GET", "/v1/quota", "", second), 200, `"remaining":4`)
	check(request("POST", "/v1/simplifications", `{"requestId":"fail","text":"synthetic input"}`, second), 503, "provider_unavailable")
	check(request("GET", "/v1/quota", "", first), 200, `"remaining":4`)
	check(request("GET", "/v1/simplifications/requests/one", "", first), 200, `"status":"succeeded"`)
	check(request("POST", "/v1/auth/sign-out", "", first), http.StatusNoContent, "")
	check(request("GET", "/v1/quota", "", first), 401, "unauthorized")
	check(request("POST", "/v1/auth/sessions", `{"idToken":"unverified"}`, second), 403, "email_not_verified")
	check(request("GET", "/v1/quota", "", second), 200, `"remaining":4`)
	linked := request("POST", "/v1/auth/sessions", `{"idToken":"verified"}`, second)
	check(linked, 200, `"remaining":4`)
	var account store.SessionResponse
	if err := json.Unmarshal(linked.Body.Bytes(), &account); err != nil || account.AccessToken == "" {
		t.Fatal("invalid account session")
	}
	check(request("GET", "/v1/quota", "", second), 401, "unauthorized")
	check(request("GET", "/v1/subscription", "", account.AccessToken), 503, "billing_unavailable")
	check(request("DELETE", "/v1/account", `{"idToken":"other"}`, account.AccessToken), 403, "reauthentication_required")
	if deleted {
		t.Fatal("deleted a different account")
	}

	docs, err := db.Collection("simplification_requests").Documents(ctx).GetAll()
	if err != nil || len(docs) != 2 {
		t.Fatalf("expected two request metadata documents: %v", err)
	}
	for _, doc := range docs {
		for _, field := range []string{"Text", "Input", "Output", "Result"} {
			if _, ok := doc.Data()[field]; ok {
				t.Fatalf("request stores %s", field)
			}
		}
	}
	check(request("DELETE", "/v1/account", `{"idToken":"verified"}`, account.AccessToken), 204, "")
	if !deleted {
		t.Fatal("Firebase deletion was not called")
	}
	check(request("GET", "/v1/quota", "", account.AccessToken), 401, "unauthorized")
}

func TestTransportBoundary(t *testing.T) {
	api := &API{PermitLimit: 1}
	handler := api.Handler()
	plain := httptest.NewRequest("GET", "http://example.test/health/live", nil)
	plain.Header.Set("X-Forwarded-Proto", "https")
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, plain)
	if w.Code != 400 || !strings.Contains(w.Body.String(), "https_required") {
		t.Fatal("trusted caller's TLS header")
	}

	cloud := (&API{PermitLimit: 1, CloudRun: true}).Handler()
	for i, prefix := range []string{"192.0.2.1", "192.0.2.2"} {
		r := httptest.NewRequest("GET", "http://example.test/health/live", nil)
		r.Header.Set("X-Forwarded-For", prefix+", 198.51.100.10")
		w := httptest.NewRecorder()
		cloud.ServeHTTP(w, r)
		if want := []int{200, 429}[i]; w.Code != want {
			t.Fatalf("expected %d, got %d", want, w.Code)
		}
	}
}
