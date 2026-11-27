package googleapi

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"golang.org/x/sync/singleflight"
)

var errUnavailable = errors.New("Google service unavailable")

type Client struct {
	http  *http.Client
	token func(context.Context) (string, error)
}

func NewClient(cloudRun bool, path, scope string) (*Client, error) {
	client := &Client{http: &http.Client{Timeout: 15 * time.Second, CheckRedirect: noRedirect}}
	var cache tokenCache
	if cloudRun {
		transport := http.DefaultTransport.(*http.Transport).Clone()
		transport.Proxy = nil
		metadata := &http.Client{Transport: transport, Timeout: 3 * time.Second, CheckRedirect: noRedirect}
		client.token = func(ctx context.Context) (string, error) {
			return cache.get(ctx, func() (accessToken, error) { return metadataToken(ctx, metadata, scope) })
		}
		return client, nil
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, errUnavailable
	}
	var credential struct{ Type string }
	if json.Unmarshal(raw, &credential) != nil || credential.Type != "service_account" {
		return nil, errUnavailable
	}
	config, err := google.JWTConfigFromJSON(raw, scope)
	if err != nil || config.TokenURL != "https://oauth2.googleapis.com/token" {
		return nil, errUnavailable
	}
	client.token = func(ctx context.Context) (string, error) {
		return cache.get(ctx, func() (accessToken, error) {
			source := config.TokenSource(context.WithValue(ctx, oauth2.HTTPClient, client.http))
			token, err := source.Token()
			if err != nil || !token.Valid() || token.Expiry.IsZero() {
				return accessToken{}, errUnavailable
			}
			return accessToken{token.AccessToken, token.Expiry.Add(-time.Minute)}, nil
		})
	}

	return client, nil
}

func noRedirect(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }

func decode(body io.Reader, result any, limit int64) error {
	raw, err := io.ReadAll(io.LimitReader(body, limit+1))
	if err != nil || int64(len(raw)) > limit || json.Unmarshal(raw, result) != nil {
		return errUnavailable
	}
	return nil
}

type accessToken struct {
	value string
	until time.Time
}

type tokenCache struct {
	mu     sync.Mutex
	flight singleflight.Group
	token  accessToken
}

func (c *tokenCache) get(ctx context.Context, fetch func() (accessToken, error)) (string, error) {
	c.mu.Lock()
	token := c.token
	c.mu.Unlock()
	if time.Now().Before(token.until) {
		return token.value, ctx.Err()
	}
	res := c.flight.DoChan("", func() (any, error) {
		c.mu.Lock()
		token := c.token
		c.mu.Unlock()
		if time.Now().Before(token.until) {
			return token.value, nil
		}
		fresh, err := fetch()
		if err != nil {
			return "", err
		}
		c.mu.Lock()
		c.token = fresh
		c.mu.Unlock()
		return fresh.value, nil
	})
	select {
	case <-ctx.Done():
		return "", ctx.Err()
	case result := <-res:
		if result.Err != nil {
			return "", result.Err
		}
		return result.Val.(string), nil
	}
}

func metadataToken(ctx context.Context, client *http.Client, scope string) (accessToken, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes="+url.QueryEscape(scope), nil)
	if err != nil {
		return accessToken{}, errUnavailable
	}
	req.Header.Set("Metadata-Flavor", "Google")
	resp, err := client.Do(req)
	if err != nil {
		return accessToken{}, errUnavailable
	}
	defer resp.Body.Close()
	var result struct {
		Token   string `json:"access_token"`
		Type    string `json:"token_type"`
		Seconds int    `json:"expires_in"`
	}
	if resp.StatusCode != 200 || resp.Header.Get("Metadata-Flavor") != "Google" ||
		decode(resp.Body, &result, 16<<10) != nil || result.Type != "Bearer" ||
		result.Seconds <= 60 || result.Seconds > 86400 || strings.TrimSpace(result.Token) == "" {
		return accessToken{}, errUnavailable
	}
	return accessToken{result.Token, time.Now().Add(time.Duration(result.Seconds-60) * time.Second)}, nil
}

func (c *Client) call(ctx context.Context, method, endpoint string, input, result any) (int, error) {
	token, err := c.token(ctx)
	if err != nil {
		return 0, err
	}
	var body io.Reader
	if input != nil {
		raw, err := json.Marshal(input)
		if err != nil {
			return 0, errUnavailable
		}
		body = bytes.NewReader(raw)
	}
	req, err := http.NewRequestWithContext(ctx, method, endpoint, body)
	if err != nil {
		return 0, errUnavailable
	}
	req.Header.Set("Authorization", "Bearer "+token)
	if input != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := c.http.Do(req)
	if err != nil {
		if ctx.Err() != nil {
			return 0, ctx.Err()
		}
		return 0, errUnavailable
	}
	defer resp.Body.Close()
	if result != nil && (resp.StatusCode/100 == 2 || resp.StatusCode == 400) {
		if err := decode(resp.Body, result, 256<<10); err != nil {
			return resp.StatusCode, err
		}
	}
	return resp.StatusCode, nil
}

const (
	IdentityScope  = "https://www.googleapis.com/auth/identitytoolkit"
	IntegrityScope = "https://www.googleapis.com/auth/playintegrity"
	BillingScope   = "https://www.googleapis.com/auth/androidpublisher"
)

type AccountStatus struct {
	Enabled    bool
	ValidSince int64
}

type Accounts struct {
	Client  *Client
	Project string
}

func (a Accounts) Status(ctx context.Context, uid string) (AccountStatus, error) {
	var out struct {
		Users []struct {
			LocalID              string
			Disabled, ValidSince json.RawMessage
		}
	}
	code, err := a.Client.call(ctx, http.MethodPost, a.endpoint("lookup"), map[string][]string{"localId": {uid}}, &out)
	if err != nil || code/100 != 2 {
		return AccountStatus{}, errUnavailable
	}
	for _, user := range out.Users {
		if user.LocalID != uid {
			continue
		}
		var since int64
		if user.ValidSince != nil {
			var raw string
			if json.Unmarshal(user.ValidSince, &raw) != nil {
				return AccountStatus{}, errUnavailable
			}
			since, err = strconv.ParseInt(raw, 10, 64)
			if err != nil || since < 0 {
				return AccountStatus{}, errUnavailable
			}
		}
		disabled := false
		switch string(user.Disabled) {
		case "true":
			disabled = true
		case "false", "":
		default:
			return AccountStatus{}, errUnavailable
		}
		return AccountStatus{!disabled, since}, nil
	}
	return AccountStatus{}, nil
}

func (a Accounts) Delete(ctx context.Context, uid string) error {
	var out struct{ Error struct{ Message string } }
	code, err := a.Client.call(ctx, http.MethodPost, a.endpoint("delete"), map[string]string{"localId": uid}, &out)
	if err == nil && (code/100 == 2 || code == 400 && out.Error.Message == "USER_NOT_FOUND") {
		return nil
	}
	return errUnavailable
}

func (a Accounts) endpoint(action string) string {
	return "https://identitytoolkit.googleapis.com/v1/projects/" + url.PathEscape(a.Project) + "/accounts:" + action
}

type AccountCache struct {
	Accounts Accounts
	mu       sync.Mutex
	entries  map[string]accountEntry
	flight   singleflight.Group
}
type accountEntry struct {
	status AccountStatus
	until  time.Time
}

func (c *AccountCache) Fresh(ctx context.Context, uid string, authTime int64) (bool, error) {
	value, err := c.Accounts.Status(ctx, uid)
	return value.Enabled && authTime > 0 && authTime >= value.ValidSince, err
}

func (c *AccountCache) cached(uid string) (accountEntry, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	entry := c.entries[uid]
	return entry, time.Now().Before(entry.until)
}

func (c *AccountCache) Allowed(ctx context.Context, uid string, authTime int64) (bool, error) {
	entry, ok := c.cached(uid)
	if !ok {
		res := c.flight.DoChan(uid, func() (any, error) {
			if cached, ok := c.cached(uid); ok {
				return cached, nil
			}
			start := time.Now()
			// Cancelling one API request does not cancel other callers' status check.
			refresh, cancel := context.WithTimeout(context.WithoutCancel(ctx), 15*time.Second)
			defer cancel()
			value, err := c.Accounts.Status(refresh, uid)
			if err != nil {
				return nil, err
			}
			entry := accountEntry{value, start.Add(5 * time.Minute)}
			c.mu.Lock()
			if c.entries == nil || len(c.entries) >= 10000 {
				c.entries = make(map[string]accountEntry)
			}
			c.entries[uid] = entry
			c.mu.Unlock()
			return entry, nil
		})
		select {
		case <-ctx.Done():
			return false, ctx.Err()
		case result := <-res:
			if result.Err != nil {
				return false, result.Err
			}
			entry = result.Val.(accountEntry)
		}
	}
	return entry.status.Enabled && authTime > 0 && authTime >= entry.status.ValidSince, nil
}
