package simplification

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"
	"unicode"

	"github.com/mbombka/SednoApp/backend/internal/telemetry"
	"github.com/mbombka/SednoApp/backend/src/Sedno.Infrastructure/Prompts"
	"github.com/rivo/uniseg"
)

const modelURL = "https://api.openai.com/v1/responses"
const maxResponseSize = 256 * 1024

var ErrProvider = errors.New("model provider unavailable")
var ErrModelTimeout = errors.New("model provider timeout")

type Model struct {
	client  *http.Client
	apiKey  string
	prompts map[string]string
}

func NewModel(apiKey string, transport http.RoundTripper) (*Model, error) {
	if apiKey == "" || strings.ContainsFunc(apiKey, unicode.IsSpace) {
		return nil, errors.New("OpenAI API key is required and must not contain whitespace")
	}
	model := &Model{
		apiKey: apiKey,
		client: &http.Client{
			Transport:     transport,
			CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse },
		},
		prompts: make(map[string]string),
	}
	for _, mode := range []string{"simplify", "correct"} {
		for language, variant := range variants {
			prompt, err := prompts.Read(mode, variant)
			if err != nil {
				return nil, err
			}
			if strings.TrimSpace(prompt) == "" {
				return nil, errors.New("empty model prompt")
			}
			model.prompts[mode+":"+language] = strings.TrimPrefix(prompt, "\ufeff")
		}
	}
	return model, nil
}

type message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

func (m *Model) Run(ctx context.Context, input Input) (string, error) {
	if err := input.Validate(); err != nil {
		return "", err
	}
	deadline, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()

	body, err := json.Marshal(map[string]any{
		"model":             "gpt-6-luna",
		"instructions":      m.prompts[input.Mode+":"+input.Language],
		"input":             []message{{Role: "user", Content: input.Text}},
		"store":             false,
		"service_tier":      "default",
		"reasoning":         map[string]string{"effort": "none"},
		"max_output_tokens": 4096,
	})
	if err != nil {
		return "", ErrProvider
	}
	req, err := http.NewRequestWithContext(deadline, http.MethodPost, modelURL, bytes.NewReader(body))
	if err != nil {
		return "", ErrProvider
	}
	req.Header.Set("Authorization", "Bearer "+m.apiKey)
	req.Header.Set("Content-Type", "application/json")
	output, err := m.send(req)
	if ctx.Err() != nil {
		return "", ctx.Err()
	}
	if deadline.Err() != nil {
		return "", ErrModelTimeout
	}
	return output, err
}

func (m *Model) send(req *http.Request) (string, error) {
	started := time.Now()
	resp, err := m.client.Do(req)
	telemetry.Record(req.Context(), "responses_headers", started)
	if err != nil {
		return "", ErrProvider
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", ErrProvider
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize+1))
	if err != nil || len(body) > maxResponseSize {
		return "", ErrProvider
	}

	var result struct {
		Status string
		Error  json.RawMessage
		Output []struct {
			Type, Role, Status string
			Content            []struct {
				Type string
				Text *string
			}
		}
	}
	if json.Unmarshal(body, &result) != nil || result.Status != "completed" ||
		(len(result.Error) > 0 && string(result.Error) != "null") {
		return "", ErrProvider
	}
	var parts []string
	for _, item := range result.Output {
		switch item.Type {
		case "":
			return "", ErrProvider
		case "message":
			if parts != nil || item.Role != "assistant" || item.Status != "completed" || len(item.Content) == 0 {
				return "", ErrProvider
			}
			parts = make([]string, 0, len(item.Content))
			for _, part := range item.Content {
				if part.Type != "output_text" || part.Text == nil {
					return "", ErrProvider
				}
				parts = append(parts, *part.Text)
			}
		}
	}
	output := strings.TrimSpace(strings.Join(parts, "\n"))
	if output == "" || uniseg.GraphemeClusterCount(output) > 16000 {
		return "", ErrProvider
	}
	telemetry.Record(req.Context(), "responses_complete", started)
	return output, nil
}
