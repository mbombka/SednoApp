package simplification

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"strings"

	"github.com/rivo/uniseg"
)

var variants = map[string]string{
	"pl": "pl", "en": "en-gb", "en-US": "en-us", "fr": "fr", "de": "de",
	"it": "it", "es": "es", "pt": "pt", "sk": "sk", "cs": "cs",
	"ro": "ro", "nb": "no", "sv": "sv",
}

type Input struct {
	RequestID string `json:"requestId"`
	Text      string `json:"text"`
	Mode      string `json:"mode"`
	Language  string `json:"language"`
}

func (i *Input) UnmarshalJSON(data []byte) error {
	type fields Input
	value := fields{Mode: "simplify", Language: "pl"}
	// Pointer fields preserve the difference between null and an omitted field.
	aux := struct {
		*fields
		Mode     json.RawMessage `json:"mode"`
		Language json.RawMessage `json:"language"`
	}{fields: &value}
	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}
	for _, field := range []struct {
		raw json.RawMessage
		dst *string
	}{{aux.Mode, &value.Mode}, {aux.Language, &value.Language}} {
		if len(field.raw) != 0 {
			*field.dst = ""
			if err := json.Unmarshal(field.raw, field.dst); err != nil {
				return err
			}
		}
	}
	*i = Input(value)
	return nil
}

type ValidationError struct {
	Code  string
	Title string
}

func (e *ValidationError) Error() string { return e.Title }

func ValidRequestID(id string) bool {
	if len(id) < 1 || len(id) > 100 {
		return false
	}
	for _, c := range id {
		if !(c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= '0' && c <= '9' || c == '-' || c == '_') {
			return false
		}
	}
	return true
}

func (i Input) Validate() error {
	switch {
	case !ValidRequestID(i.RequestID):
		return &ValidationError{"invalid_request_id", "Nieprawidłowy identyfikator żądania."}
	case i.Mode != "simplify" && i.Mode != "correct":
		return &ValidationError{"invalid_mode", "Nieprawidłowy tryb tekstu."}
	case variants[i.Language] == "":
		return &ValidationError{"invalid_language", "Unsupported text language."}
	default:
		return validateText(i.Text)
	}
}

func validateText(value string) error {
	switch {
	case strings.TrimSpace(value) == "":
		return &ValidationError{"empty_text", "Wpisz tekst."}
	case uniseg.GraphemeClusterCount(value) > 4000:
		return &ValidationError{"text_too_long", "Tekst może mieć maksymalnie 4000 znaków."}
	default:
		return nil
	}
}

func HMAC(key []byte, value string) string {
	return strings.ToUpper(hex.EncodeToString(mac(key, value)))
}

func mac(key []byte, value string) []byte {
	hash := hmac.New(sha256.New, key)
	hash.Write([]byte(value))
	return hash.Sum(nil)
}

func (i Input) Fingerprint(key []byte) string {
	if i.Mode == "correct" {
		key = mac(key, "sedno.correct.v1")
	}
	if i.Language != "pl" {
		key = mac(key, "sedno.language.v1:"+i.Language)
	}
	return HMAC(key, i.Text)
}
