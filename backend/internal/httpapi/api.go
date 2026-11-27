package httpapi

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"mime"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"
	"unicode/utf16"

	"github.com/mbombka/SednoApp/backend/internal/simplification"
	"github.com/mbombka/SednoApp/backend/internal/store"
)

const bodyLimit = 128 * 1024

type API struct {
	Store          *store.Store
	CredentialKey  []byte
	FingerprintKey []byte
	RunModel       func(context.Context, simplification.Input) (string, error)

	mu     sync.Mutex
	window time.Time
	counts map[string]int
}

type problemDetails struct {
	Type   string       `json:"type"`
	Status int          `json:"status"`
	Code   string       `json:"code"`
	Title  string       `json:"title"`
	Quota  *store.Quota `json:"quota,omitempty"`
}

type problemError struct {
	status int
	code   string
	title  string
}

func (p problemError) Error() string { return p.title }

func writeJSON(w http.ResponseWriter, status int, body any) {
	if w.Header().Get("Content-Type") == "" {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
	}
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}

func problem(w http.ResponseWriter, status int, code, title string, quota *store.Quota) {
	w.Header().Set("Content-Type", "application/problem+json")
	writeJSON(w, status, problemDetails{"about:blank", status, code, title, quota})
}

func decode(w http.ResponseWriter, r *http.Request, input any) error {
	r.Body = http.MaxBytesReader(w, r.Body, bodyLimit)
	contentType, _, _ := mime.ParseMediaType(r.Header.Get("Content-Type"))
	if contentType != "application/json" && !strings.HasSuffix(contentType, "+json") {
		return problemError{400, "invalid_request", "Nieprawidłowe żądanie."}
	}
	decoder := json.NewDecoder(r.Body)
	err := decoder.Decode(input)
	if err == nil {
		err = decoder.Decode(new(json.RawMessage))
		if err == io.EOF {
			return nil
		}
	}
	var tooLarge *http.MaxBytesError
	if errors.As(err, &tooLarge) {
		return problemError{413, "request_too_large", "Żądanie jest zbyt duże."}
	}
	return problemError{400, "invalid_json", "Nieprawidłowe dane."}
}

func (a *API) limited(key string) bool {
	a.mu.Lock()
	defer a.mu.Unlock()
	now := time.Now()
	if a.window.IsZero() || now.Sub(a.window) >= time.Minute {
		a.window, a.counts = now, make(map[string]int)
	}
	if a.counts[key] >= 60 {
		return true
	}
	a.counts[key]++
	return false
}

type authenticatedHandler func(http.ResponseWriter, *http.Request, *store.Session) error

func (a *API) protected(handler authenticatedHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		var session *store.Session
		if len(header) >= 7 && strings.EqualFold(header[:7], "Bearer ") {
			var err error
			session, err = a.Store.Authenticate(r.Context(), header[7:], a.CredentialKey, nil)
			if err != nil {
				handleError(w, r, err)
				return
			}
		}
		key := peerKey(r)
		if session != nil {
			key = "guest:" + session.IdentityID
		}
		if a.limited(key) {
			problem(w, 429, "rate_limited", "Zbyt wiele żądań.", nil)
			return
		}
		if session == nil {
			problem(w, 401, "unauthorized", "Brak ważnej sesji.", nil)
			return
		}
		handleError(w, r, handler(w, r, session))
	}
}

func peerKey(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = "unknown"
	}
	return "network:" + host
}

func handleError(w http.ResponseWriter, r *http.Request, err error) {
	if err == nil || errors.Is(r.Context().Err(), context.Canceled) {
		return
	}
	var validation *simplification.ValidationError
	var detail problemError
	switch {
	case errors.As(err, &detail):
		problem(w, detail.status, detail.code, detail.title, nil)
	case errors.As(err, &validation):
		problem(w, 400, validation.Code, validation.Title, nil)
	case r.URL.Path == "/v1/simplifications" && errors.Is(r.Context().Err(), context.DeadlineExceeded):
		problem(w, 504, "simplification_timeout", "Upraszczanie trwało zbyt długo. Spróbuj ponownie.", nil)
	default:
		problem(w, 500, "server_error", "Wystąpił błąd serwera.", nil)
	}
}

// Handler serves an isolated development API. It is bound to loopback by the
// development command and uses an explicit mock installation verifier.
func (a *API) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health/live", func(w http.ResponseWriter, r *http.Request) {
		_, _ = io.WriteString(w, "Healthy")
	})
	mux.HandleFunc("GET /health/ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()
		if !a.Store.Ready(ctx) {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		writeJSON(w, 200, map[string]string{"status": "ready"})
	})
	mux.HandleFunc("POST /v1/guest-sessions", func(w http.ResponseWriter, r *http.Request) {
		if a.limited(peerKey(r)) {
			problem(w, 429, "rate_limited", "Zbyt wiele żądań.", nil)
			return
		}
		handleError(w, r, a.createGuest(w, r))
	})
	mux.HandleFunc("GET /v1/quota", a.protected(a.quota))
	mux.HandleFunc("POST /v1/auth/sign-out", a.protected(a.signOut))
	mux.HandleFunc("POST /v1/simplifications", a.protected(a.simplify))
	mux.HandleFunc("GET /v1/simplifications/requests/{requestId}", a.protected(a.status))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		if r.ContentLength > bodyLimit {
			problem(w, 413, "request_too_large", "Żądanie jest zbyt duże.", nil)
			return
		}
		if r.URL.Path == "/v1/simplifications" {
			ctx, cancel := context.WithTimeout(r.Context(), 9*time.Second)
			defer cancel()
			r = r.WithContext(ctx)
		}
		mux.ServeHTTP(w, r)
	})
}

func (a *API) createGuest(w http.ResponseWriter, r *http.Request) error {
	var input *struct {
		InstallationID string `json:"installationId"`
		IntegrityToken string `json:"integrityToken"`
	}
	if err := decode(w, r, &input); err != nil {
		return err
	}
	if input == nil || strings.TrimSpace(input.InstallationID) == "" || len(utf16.Encode([]rune(input.InstallationID))) > 200 {
		return problemError{400, "invalid_installation_id", "Nieprawidłowy identyfikator instalacji."}
	}
	if input.IntegrityToken != "development-ok" {
		return problemError{403, "integrity_failed", "Nie można potwierdzić instalacji."}
	}
	session, err := a.Store.CreateGuest(r.Context(), input.InstallationID, a.CredentialKey)
	if err != nil {
		return err
	}
	writeJSON(w, 200, session)
	return nil
}

func (a *API) quota(w http.ResponseWriter, r *http.Request, s *store.Session) error {
	quota, err := a.Store.Quota(r.Context(), s.IdentityID, false)
	if err != nil {
		return err
	}
	writeJSON(w, 200, quota)
	return nil
}

func (a *API) signOut(w http.ResponseWriter, r *http.Request, s *store.Session) error {
	if err := a.Store.SignOut(r.Context(), s); err != nil {
		return err
	}
	w.WriteHeader(http.StatusNoContent)
	return nil
}

func (a *API) status(w http.ResponseWriter, r *http.Request, s *store.Session) error {
	id := r.PathValue("requestId")
	if !simplification.ValidRequestID(id) {
		return problemError{400, "invalid_request_id", "Nieprawidłowy identyfikator żądania."}
	}
	result, err := a.Store.Status(r.Context(), s.IdentityID, id, false)
	if err != nil {
		return err
	}
	if result == nil {
		return problemError{404, "request_not_found", "Nie znaleziono żądania."}
	}
	writeJSON(w, 200, result)
	return nil
}

func (a *API) simplify(w http.ResponseWriter, r *http.Request, s *store.Session) error {
	var input *simplification.Input
	if err := decode(w, r, &input); err != nil {
		return err
	}
	if input == nil {
		return problemError{400, "invalid_json", "Nieprawidłowe dane."}
	}
	if err := input.Validate(); err != nil {
		return err
	}
	ctx := r.Context()
	kind, quota, err := a.Store.Reserve(ctx, s.IdentityID, input.RequestID, input.Fingerprint(a.FingerprintKey), false)
	if err != nil {
		return err
	}
	switch kind {
	case "processing":
		w.Header().Set("Location", "/v1/simplifications/requests/"+input.RequestID)
		writeJSON(w, 202, map[string]any{"status": "processing", "quota": quota})
		return nil
	case "key_conflict":
		return problemError{409, "key_conflict", "Identyfikator żądania jest już użyty."}
	case "result_unavailable":
		return problemError{409, "result_unavailable", "Wynik tego żądania nie jest już dostępny. Użyj nowego identyfikatora."}
	case "quota_exceeded":
		problem(w, 429, "quota_exceeded", "Wykorzystano dzienny limit.", &quota)
		return nil
	case "expired":
		return problemError{409, "reservation_expired", "Czas tego żądania minął. Użyj nowego identyfikatora."}
	case "failed":
		return problemError{409, "request_failed", "Poprzednia próba nie powiodła się. Użyj nowego identyfikatora."}
	case "reserved":
	default:
		return errors.New("invalid reservation outcome")
	}
	output, err := a.RunModel(ctx, *input)
	if ctx.Err() != nil {
		// An interrupted request cannot tell whether the model processed it.
		return ctx.Err()
	}
	if err != nil {
		if _, finishErr := a.Store.Finish(ctx, s.IdentityID, input.RequestID, false); finishErr != nil {
			return finishErr
		}
		if errors.Is(err, simplification.ErrModelTimeout) {
			return problemError{504, "simplification_timeout", "Upraszczanie trwało zbyt długo. Spróbuj ponownie."}
		}
		return problemError{503, "provider_unavailable", "Usługa upraszczania jest chwilowo niedostępna."}
	}
	completed, err := a.Store.Finish(ctx, s.IdentityID, input.RequestID, true)
	if err != nil {
		return err
	}
	if !completed {
		return problemError{409, "reservation_expired", "Czas tego żądania minął. Użyj nowego identyfikatora."}
	}
	quota, err = a.Store.Quota(ctx, s.IdentityID, false)
	if err != nil {
		return err
	}
	writeJSON(w, 200, map[string]any{"quota": quota, "result": map[string]any{
		"id": input.RequestID, "text": output, "createdAt": a.Store.Now().UTC(), "mode": input.Mode, "language": input.Language,
	}})
	return nil
}
