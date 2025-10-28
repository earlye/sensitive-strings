package sensitivestring

import (
	"crypto/sha256"
	"encoding/json"
	"fmt"
)

// SensitiveString wraps a string value and prevents accidental serialization
// of secrets by returning a SHA256 hash instead of the raw value.
type SensitiveString struct {
	value string
}

// New creates a new SensitiveString from the given value.
func New(value string) *SensitiveString {
	return &SensitiveString{value: value}
}

// String returns the SHA256 hash of the value, implementing fmt.Stringer.
// This prevents accidental exposure in logs, string concatenation, etc.
func (s *SensitiveString) String() string {
	if s == nil {
		return ""
	}
	hash := sha256.Sum256([]byte(s.value))
	return fmt.Sprintf("sha256:%x", hash)
}

// GoString returns the SHA256 hash representation for %#v formatting.
// This implements fmt.GoStringer to prevent accidental exposure even when
// using Go-syntax formatting for debugging.
func (s *SensitiveString) GoString() string {
	if s == nil {
		return "(*SensitiveString)(nil)"
	}
	return fmt.Sprintf("&sensitivestring.SensitiveString{value:%q}", s.String())
}

// Value returns the raw plaintext value. Use this only when you explicitly
// need access to the secret value.
func (s *SensitiveString) Value() string {
	if s == nil {
		return ""
	}
	return s.value
}

// Len returns the length of the underlying value without exposing it.
func (s *SensitiveString) Len() int {
	if s == nil {
		return 0
	}
	return len(s.value)
}

// MarshalJSON implements json.Marshaler, returning the SHA256 hash instead
// of the raw value to prevent accidental serialization of secrets.
func (s *SensitiveString) MarshalJSON() ([]byte, error) {
	if s == nil {
		return json.Marshal(nil)
	}
	return json.Marshal(s.String())
}

// UnmarshalJSON implements json.Unmarshaler.
// Note: This unmarshals the SHA256 hash, not the original value.
// This is intentional - you cannot recover the original value from the hash.
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
func (s *SensitiveString) MarshalYAML() (interface{}, error) {
	if s == nil {
		return nil, nil
	}
	return s.String(), nil
}

// IsSensitiveString returns true if the input is a *SensitiveString.
func IsSensitiveString(input interface{}) bool {
	if input == nil {
		return false
	}
	_, ok := input.(*SensitiveString)
	return ok
}

// ExtractValue returns the raw value from a *SensitiveString or string.
// If input is nil or not a supported type, returns empty string and false.
func ExtractValue(input interface{}) (string, bool) {
	if input == nil {
		return "", false
	}

	switch v := input.(type) {
	case *SensitiveString:
		if v == nil {
			return "", false
		}
		return v.Value(), true
	case string:
		return v, true
	default:
		return "", false
	}
}

// ExtractRequiredValue returns the raw value from a *SensitiveString or string.
// Panics if input is nil or not a supported type.
func ExtractRequiredValue(input interface{}) string {
	value, ok := ExtractValue(input)
	if !ok {
		panic("ExtractRequiredValue: input must be a string or *SensitiveString")
	}
	return value
}

// Sensitive converts input into a *SensitiveString.
// If input is already a *SensitiveString, returns it unchanged.
// If input is nil, returns nil.
func Sensitive(input interface{}) *SensitiveString {
	if input == nil {
		return nil
	}

	if ss, ok := input.(*SensitiveString); ok {
		return ss
	}

	// Try to convert to string
	var str string
	switch v := input.(type) {
	case string:
		str = v
	case fmt.Stringer:
		str = v.String()
	default:
		str = fmt.Sprintf("%v", v)
	}

	return New(str)
}

// PlaintextReplacer returns a custom JSON marshaler function that
// extracts the plaintext value of SensitiveString objects during
// serialization. Use this ONLY when you explicitly need to serialize
// secrets (e.g., sending credentials to an authentication service).
//
// Example:
//
//	data := map[string]interface{}{
//	  "username": "user",
//	  "password": sensitivestring.New("secret123"),
//	}
//	json.Marshal(data) // password will be hashed
//
//	// To get plaintext:
//	result := sensitivestring.PlaintextReplacer(data)
//	json.Marshal(result) // password will be "secret123"
func PlaintextReplacer(data interface{}) interface{} {
	switch v := data.(type) {
	case *SensitiveString:
		if v == nil {
			return nil
		}
		return v.Value()
	case map[string]interface{}:
		result := make(map[string]interface{}, len(v))
		for key, val := range v {
			result[key] = PlaintextReplacer(val)
		}
		return result
	case []interface{}:
		result := make([]interface{}, len(v))
		for i, val := range v {
			result[i] = PlaintextReplacer(val)
		}
		return result
	default:
		return v
	}
}
