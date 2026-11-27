package main

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCloudRunDefaultsAndMockRejection(t *testing.T) {
	key := base64.StdEncoding.EncodeToString(make([]byte, 32))
	t.Setenv("Security__CredentialKey", key)
	t.Setenv("Security__FingerprintKey", key)
	t.Setenv("OpenAI__ApiKey", "synthetic-test-key")
	t.Setenv("Model__Provider", "openai")
	t.Setenv("PlayIntegrity__Provider", "google")
	t.Setenv("Billing__Enabled", "false")
	t.Setenv("SEDNO_PRIVACY_PATH", filepath.Join("..", "..", "..", "docs", "public", "prywatnosc", "index.html"))
	t.Setenv("Privacy__DeletionEmail", "")
	if err := os.Unsetenv("Privacy__DeletionEmail"); err != nil {
		t.Fatal(err)
	}
	api, err := configure(nil, false, true, true)
	if err != nil || api.DeletionEmail != "contact@sedno.xyz" {
		t.Fatalf("Cloud Run defaults failed: %v", err)
	}
	t.Setenv("PlayIntegrity__Provider", "mock")
	if _, err := configure(nil, false, true, true); err == nil || !strings.Contains(err.Error(), "Development-only") {
		t.Fatal("production accepted mock Play Integrity")
	}
	t.Setenv("Model__Provider", "mock")
	if _, err := configure(nil, false, true, true); err == nil || !strings.Contains(err.Error(), "model mock is Development-only") {
		t.Fatal("production accepted mock model")
	}
}
