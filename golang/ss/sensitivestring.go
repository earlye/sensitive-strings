package sensitivestring

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"log/slog"
)

// SensitiveString wraps a string value and prevents accidental serialization
// of secrets by returning a SHA256 hash instead of the raw value.
type SensitiveString struct {
	value string
}

// New creates a new SensitiveString from the given value.
func New(value string) SensitiveString {
	return SensitiveString{value: value}
}

// String returns the SHA256 hash of the value, implementing fmt.Stringer.
// This prevents accidental exposure in logs, string concatenation, etc.
// Uses a value receiver so it is callable on both value and pointer types.
func (s SensitiveString) String() string {
	hash := sha256.Sum256([]byte(s.value))
	return fmt.Sprintf("sha256:%x", hash)
}

// GoString returns the SHA256 hash representation for %#v formatting.
// This implements fmt.GoStringer to prevent accidental exposure even when
// using Go-syntax formatting for debugging.
// Uses a value receiver so it is callable on both value and pointer types.
func (s SensitiveString) GoString() string {
	return fmt.Sprintf("sensitivestring.SensitiveString{value:%q}", s.String())
}

// PlainText returns the raw plaintext value. Use this only when you explicitly
// need access to the secret value.
func (s SensitiveString) PlainText() string {
	return s.value
}

// PValue returns a pointer to the raw plaintext value. Use this when you
// need to pass plaintext value to a function that expects a string pointer.
// Common example is for Cobra string arguments.
// The receiver is a pointer so that the address of `*s.value` is returned rather
// than the address of a copy.
// A nil receiver will panic.
func (s *SensitiveString) PValue() *string {
	if s == nil {
		panic("PValue: receiver is nil")
	}
	return &s.value
}

// Len returns the length of the underlying value without exposing it.
func (s SensitiveString) Len() int {
	return len(s.value)
}

// MarshalJSON implements json.Marshaler, returning the SHA256 hash instead
// of the raw value to prevent accidental serialization of secrets.
// Uses a value receiver so it is callable on both value and pointer types.
func (s SensitiveString) MarshalJSON() ([]byte, error) {
	return json.Marshal(s.String())
}

// UnmarshalJSON implements json.Unmarshaler.
// Note: If the JSON has a hash in it (i.e., it was marshaled with MarshalYAML rather than PlaintextReplacer),
// this will unmarshal that hash, not the original value.
// This is intentional - you cannot recover the original value from the hash.
// The receiver is a pointer so that it can properly implement json.Unmarshaler; it must
// be a pointer to be able to modify `s`.
func (s *SensitiveString) UnmarshalJSON(data []byte) error {
	var str string
	if err := json.Unmarshal(data, &str); err != nil {
		return err
	}
	s.value = str
	return nil
}

// MarshalYAML implements yaml.Marshaler, returning the SHA256 hash instead
// of the raw value to prevent accidental serialization of secrets.
// Uses a value receiver so it is callable on both value and pointer types.
func (s SensitiveString) MarshalYAML() (interface{}, error) {
	return s.String(), nil
}

// LogValue implements slog.LogValuer, returning the SHA256 hash so that
// slog never logs the plaintext value regardless of handler type.
// Uses a value receiver so it is callable on both value and pointer types.
func (s SensitiveString) LogValue() slog.Value {
	return slog.StringValue(s.String())
}

// IsSensitiveString returns true if the input is a SensitiveString or *SensitiveString.
func IsSensitiveString(input any) bool {
	if input == nil {
		return false
	}
	switch input.(type) {
	case *SensitiveString: // nil *SensitiveString covered by nil check above.
		return true
	case SensitiveString:
		return true
	}
	return false
}

// ExtractPlainText returns the raw value from a *SensitiveString, SensitiveString, or string.
// If input is nil or not a supported type, returns empty string and false.
func ExtractPlainText(input any) (string, bool) {
	if input == nil {
		return "", false
	}

	switch v := input.(type) {
	case *SensitiveString: // nil *SensitiveString covered by nil check above.
		return v.PlainText(), true
	case SensitiveString:
		return v.PlainText(), true
	case string:
		return v, true
	default:
		return "", false
	}
}

// ExtractRequiredPlainText returns the raw value from a SensitiveString, *SensitiveString, or string.
// Panics if input is nil or not a supported type.
func ExtractRequiredPlainText(input any) string {
	value, ok := ExtractPlainText(input)
	if !ok {
		panic("ExtractRequiredPlainText: input must be a string, SensitiveString, or *SensitiveString")
	}
	return value
}

// Sensitive converts input into a *SensitiveString.
// If input is already a *SensitiveString, returns it unchanged.
// If input is nil, returns new empty SensitiveString.
func Sensitive(input any) *SensitiveString {
	if input == nil {
		return &SensitiveString{}
	}

	if ss, ok := input.(*SensitiveString); ok {
		return ss
	}

	// Try to convert to string
	var str string
	switch v := input.(type) {
	case string:
		str = v
	case SensitiveString:
		str = v.PlainText()
	case fmt.Stringer:
		str = v.String()
	default:
		str = fmt.Sprintf("%v", v)
	}

	return &SensitiveString{value: str}
}

// PlaintextReplacer returns a custom JSON marshaler function that
// extracts the plaintext value of SensitiveString objects during
// serialization. Use this ONLY when you explicitly need to serialize
// secrets (e.g., sending credentials to an authentication service).
//
// Example:
//
//	data := map[string]any{
//	  "username": "user",
//	  "password": sensitivestring.New("secret123"),
//	}
//	json.Marshal(data) // password will be hashed
//
//	// To get plaintext:
//	result := sensitivestring.PlaintextReplacer(data)
//	json.Marshal(result) // password will be "secret123"
func PlaintextReplacer(data any) any {
	switch v := data.(type) {
	case *SensitiveString:
		if v == nil {
			return nil
		}
		return v.PlainText()
	case SensitiveString:
		return v.PlainText()
	case map[string]any:
		result := make(map[string]any, len(v))
		for key, val := range v {
			result[key] = PlaintextReplacer(val)
		}
		return result
	case []any:
		result := make([]any, len(v))
		for i, val := range v {
			result[i] = PlaintextReplacer(val)
		}
		return result
	default:
		return v
	}
}
