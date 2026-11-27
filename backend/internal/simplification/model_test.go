package simplification

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/mbombka/SednoApp/backend/src/Sedno.Infrastructure/Prompts"
)

type fakeTransport func(*http.Request) (*http.Response, error)

func (f fakeTransport) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

func TestResponsesProtocol(t *testing.T) {
	for _, test := range []struct {
		name, body string
		valid      bool
	}{
		{"complete", `{"status":"completed","output":[{"type":"message","role":"assistant","status":"completed","content":[{"type":"output_text","text":" First "},{"type":"output_text","text":"Second " }]}]}`, true},
		{"incomplete", `{"status":"incomplete"}`, false},
		{"refusal", `{"status":"completed","output":[{"type":"message","role":"assistant","status":"completed","content":[{"type":"refusal","text":"no"}]}]}`, false},
		{"oversized", strings.Repeat(" ", maxResponseSize+1), false},
	} {
		t.Run(test.name, func(t *testing.T) {
			model, err := NewModel("test-key", fakeTransport(func(r *http.Request) (*http.Response, error) {
				if r.URL.String() != modelURL || r.Header.Get("Authorization") != "Bearer test-key" {
					t.Fatal("unexpected provider destination or authentication")
				}
				var payload map[string]any
				if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
					t.Fatal(err)
				}
				want, _ := prompts.Read("correct", "no")
				if payload["instructions"] != strings.TrimPrefix(want, "\ufeff") || payload["model"] != "gpt-6-luna" ||
					payload["store"] != false || payload["service_tier"] != "default" || payload["max_output_tokens"] != float64(4096) ||
					payload["reasoning"].(map[string]any)["effort"] != "none" || payload["conversation"] != nil || payload["previous_response_id"] != nil {
					t.Fatal("unexpected provider settings")
				}
				return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(test.body))}, nil
			}))
			if err != nil {
				t.Fatal(err)
			}
			result, err := model.Run(context.Background(), Input{"request", "original", "correct", "nb"})
			if test.valid {
				if err != nil || result != "First \nSecond" {
					t.Fatalf("unexpected result %q and error %v", result, err)
				}
			} else if result != "" || !errors.Is(err, ErrProvider) {
				t.Fatalf("unexpected result %q and error %v", result, err)
			}
		})
	}
}

func TestInputDefaultsAndNull(t *testing.T) {
	for _, test := range []struct{ extra, code string }{
		{"", ""},
		{`,"mode":null`, "invalid_mode"},
		{`,"language":null`, "invalid_language"},
	} {
		var input Input
		if err := json.Unmarshal([]byte(`{"requestId":"a","text":"Tekst"`+test.extra+`}`), &input); err != nil {
			t.Fatal(err)
		}
		err := input.Validate()
		var validation *ValidationError
		if test.code == "" && err != nil || test.code != "" && (!errors.As(err, &validation) || validation.Code != test.code) {
			t.Fatalf("unexpected validation error for %q: %v", test.extra, err)
		}
	}
}
