package keyring

import (
	"encoding/base64"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestProtectAndRejectTampering(t *testing.T) {
	path := t.TempDir()
	if err := Initialize(path); err != nil {
		t.Fatal(err)
	}
	if err := Initialize(path); err == nil {
		t.Fatal("initialized an existing ring")
	}
	first, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	proof, err := first.Protect("synthetic.GooglePlay/test")
	if err != nil {
		t.Fatal(err)
	}
	second, err := Open(path)
	if err != nil {
		t.Fatal(err)
	}
	value, err := second.Unprotect(proof)
	if err != nil || value != "synthetic.GooglePlay/test" {
		t.Fatal("could not read token from another instance")
	}
	payload, err := base64.RawURLEncoding.DecodeString(proof)
	if err != nil {
		t.Fatal(err)
	}
	for _, pos := range []int{0, 4, 20, 36, 52, len(payload) - 1} {
		payload[pos] ^= 1
		if _, err := second.Unprotect(base64.RawURLEncoding.EncodeToString(payload)); err == nil {
			t.Fatalf("accepted tampering at offset %d", pos)
		}
		payload[pos] ^= 1
	}
}

func TestDotnetInterop(t *testing.T) {
	path := os.Getenv("SEDNO_TEST_DOTNET_ORACLE")
	if path == "" {
		t.Skip("synthetic .NET key ring and token required")
	}
	protector, err := Open(filepath.Join(path, "test-keyring"))
	if err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(filepath.Join(path, "dotnet-purchase.synthetic"))
	if err != nil {
		t.Fatal(err)
	}
	value, err := protector.Unprotect(strings.TrimSpace(string(data)))
	if err != nil || value != "synthetic.GooglePlay/test" {
		t.Fatalf("Go rejected the .NET token: %v", err)
	}
	result, err := protector.Protect(value)
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(path, "go-purchase.synthetic"), []byte(result+"\n"), 0600); err != nil {
		t.Fatal(err)
	}
}
