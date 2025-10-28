package sensitivestring

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

// TestNew_af5a2178 verifies basic creation and hiding of values
func TestNew_af5a2178(t *testing.T) {
	ss := New("foo")
	expected := "sha256:2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"

	if got := ss.String(); got != expected {
		t.Errorf("String() = %v, want %v", got, expected)
	}

	// Test string formatting (equivalent to template literals in JS)
	formatted := fmt.Sprintf("%s", ss)
	if formatted != expected {
		t.Errorf("fmt.Sprintf(%%s) = %v, want %v", formatted, expected)
	}

	formatted = fmt.Sprintf("%v", ss)
	if formatted != expected {
		t.Errorf("fmt.Sprintf(%%v) = %v, want %v", formatted, expected)
	}
}

// TestValue_af5a2178 verifies explicit value access
func TestValue_af5a2178(t *testing.T) {
	ss := New("foo")

	if got := ss.Value(); got != "foo" {
		t.Errorf("Value() = %v, want %v", got, "foo")
	}
}

// TestJSONMarshal_af5a2178 verifies JSON serialization hides the value
func TestJSONMarshal_af5a2178(t *testing.T) {
	ss := New("foo")
	expected := "sha256:2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae"

	obj := map[string]interface{}{
		"ss": ss,
		"b":  "c",
	}

	jsonBytes, err := json.Marshal(obj)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v", err)
	}

	jsonStr := string(jsonBytes)
	if !strings.Contains(jsonStr, expected) {
		t.Errorf("JSON output should contain hash, got: %v", jsonStr)
	}

	if strings.Contains(jsonStr, "foo") && !strings.Contains(jsonStr, "sha256") {
		t.Errorf("JSON output leaked raw value: %v", jsonStr)
	}
}

// TestExtractValue_666e8222 verifies ExtractValue can get values
func TestExtractValue_666e8222(t *testing.T) {
	ss := New("foo")
	s := "notfoo"

	val, ok := ExtractValue(ss)
	if !ok || val != "foo" {
		t.Errorf("ExtractValue(ss) = (%v, %v), want (foo, true)", val, ok)
	}

	val, ok = ExtractValue(s)
	if !ok || val != "notfoo" {
		t.Errorf("ExtractValue(s) = (%v, %v), want (notfoo, true)", val, ok)
	}

	val, ok = ExtractValue(nil)
	if ok {
		t.Errorf("ExtractValue(nil) = (%v, %v), want (empty, false)", val, ok)
	}
}

// TestExtractRequiredValue_3325a6ad verifies ExtractRequiredValue can get values
func TestExtractRequiredValue_3325a6ad(t *testing.T) {
	ss := New("foo")
	s := "notfoo"

	if got := ExtractRequiredValue(ss); got != "foo" {
		t.Errorf("ExtractRequiredValue(ss) = %v, want foo", got)
	}

	if got := ExtractRequiredValue(s); got != "notfoo" {
		t.Errorf("ExtractRequiredValue(s) = %v, want notfoo", got)
	}

	// Test panic case
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("ExtractRequiredValue(nil) should panic")
		}
	}()
	ExtractRequiredValue(nil)
}

// TestSensitive_a23eb5b8 verifies Sensitive can create SensitiveString from various types
func TestSensitive_a23eb5b8(t *testing.T) {
	ss := New("foo")
	s := "notfoo"

	result := Sensitive(ss)
	if result != ss {
		t.Errorf("Sensitive(ss) should return same instance")
	}

	result = Sensitive(s)
	if result.Value() != "notfoo" {
		t.Errorf("Sensitive(s).Value() = %v, want notfoo", result.Value())
	}

	result = Sensitive(nil)
	if result != nil {
		t.Errorf("Sensitive(nil) = %v, want nil", result)
	}
}

// TestIsSensitiveString_a23eb5b8 verifies IsSensitiveString detection
func TestIsSensitiveString_a23eb5b8(t *testing.T) {
	ss := New("foo")
	s := "notfoo"

	if !IsSensitiveString(ss) {
		t.Errorf("IsSensitiveString(ss) = false, want true")
	}

	if IsSensitiveString(s) {
		t.Errorf("IsSensitiveString(s) = true, want false")
	}

	if IsSensitiveString(nil) {
		t.Errorf("IsSensitiveString(nil) = true, want false")
	}
}

// TestLen_088caed0 verifies length access
func TestLen_088caed0(t *testing.T) {
	ss := New("foo")
	if got := ss.Len(); got != 3 {
		t.Errorf("Len() = %v, want 3", got)
	}
}

// TestNilSensitiveString verifies nil handling
func TestNilSensitiveString(t *testing.T) {
	var ss *SensitiveString

	if got := ss.String(); got != "" {
		t.Errorf("nil.String() = %v, want empty string", got)
	}

	if got := ss.Value(); got != "" {
		t.Errorf("nil.Value() = %v, want empty string", got)
	}

	if got := ss.Len(); got != 0 {
		t.Errorf("nil.Len() = %v, want 0", got)
	}
}

// Test455A1E09_StringFormatting verifies string formatting doesn't leak
func Test455A1E09_StringFormatting(t *testing.T) {
	ss := New("secret123")

	// Test various formatting verbs
	tests := []struct {
		format string
		name   string
	}{
		{"%s", "string"},
		{"%v", "default"},
		{"%+v", "verbose"},
		{"%#v", "Go-syntax"},
		{"%q", "quoted"},
	}

	for _, tt := range tests {
		result := fmt.Sprintf(tt.format, ss)
		if strings.Contains(result, "secret123") && !strings.Contains(result, "sha256") {
			t.Errorf("fmt.Sprintf(%s) leaked raw value: %v", tt.name, result)
		}
		t.Logf("%s formatting: %s", tt.name, result)
	}
}

// Test458ECC56_StructSerialization verifies struct fields don't leak
func Test458ECC56_StructSerialization(t *testing.T) {
	type Credentials struct {
		Username string           `json:"username"`
		Password *SensitiveString `json:"password"`
	}

	creds := Credentials{
		Username: "user123",
		Password: New("secret789"),
	}

	jsonBytes, err := json.Marshal(creds)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v", err)
	}

	jsonStr := string(jsonBytes)
	t.Logf("JSON serialization: %s", jsonStr)

	if strings.Contains(jsonStr, "secret789") && !strings.Contains(jsonStr, "sha256") {
		t.Errorf("JSON serialization leaked raw password value")
	}

	if !strings.Contains(jsonStr, "sha256:") {
		t.Errorf("JSON serialization should contain sha256 hash")
	}
}

// TestC9D43D4F_YAML verifies YAML serialization doesn't leak
func TestC9D43D4F_YAML(t *testing.T) {
	type Config struct {
		Username string           `yaml:"username"`
		Password *SensitiveString `yaml:"password"`
		Nested   struct {
			APIKey *SensitiveString `yaml:"apiKey"`
		} `yaml:"nested"`
	}

	config := Config{
		Username: "testuser",
		Password: New("secretYaml"),
	}
	config.Nested.APIKey = New("secretApiKey")

	yamlBytes, err := yaml.Marshal(config)
	if err != nil {
		t.Fatalf("yaml.Marshal() error = %v", err)
	}

	yamlStr := string(yamlBytes)
	t.Logf("YAML serialization:\n%s", yamlStr)

	if strings.Contains(yamlStr, "secretYaml") && !strings.Contains(yamlStr, "sha256") {
		t.Errorf("YAML serialization leaked password raw value")
	}

	if strings.Contains(yamlStr, "secretApiKey") && !strings.Contains(yamlStr, "sha256") {
		t.Errorf("YAML serialization leaked apiKey raw value")
	}

	if !strings.Contains(yamlStr, "sha256:") {
		t.Errorf("YAML serialization should contain sha256 hash")
	}
}

// Test404A48D7_YAML verifies PlaintextReplacer with YAML
func Test404A48D7_YAML(t *testing.T) {
	obj := map[string]interface{}{
		"username": "testuser",
		"password": New("secretYamlUnsecured"),
		"nested": map[string]interface{}{
			"apiKey": New("secretUnsecuredApiKey"),
		},
	}

	// Apply PlaintextReplacer before marshaling
	plainObj := PlaintextReplacer(obj)

	yamlBytes, err := yaml.Marshal(plainObj)
	if err != nil {
		t.Fatalf("yaml.Marshal() error = %v", err)
	}

	yamlStr := string(yamlBytes)
	t.Logf("YAML with PlaintextReplacer:\n%s", yamlStr)

	if !strings.Contains(yamlStr, "secretYamlUnsecured") {
		t.Errorf("YAML with PlaintextReplacer should include password raw value")
	}

	if !strings.Contains(yamlStr, "secretUnsecuredApiKey") {
		t.Errorf("YAML with PlaintextReplacer should include apiKey raw value")
	}

	if strings.Contains(yamlStr, "sha256:") {
		t.Errorf("YAML with PlaintextReplacer should NOT contain sha256 hash")
	}
}

// TestPlaintextReplacer_JSON verifies PlaintextReplacer with JSON
func TestPlaintextReplacer_JSON(t *testing.T) {
	obj := map[string]interface{}{
		"username": "testuser",
		"password": New("secretJSON"),
		"nested": map[string]interface{}{
			"apiKey": New("secretNestedJSON"),
		},
		"array": []interface{}{
			New("secretInArray"),
			"normalString",
		},
	}

	// Normal serialization (should hash)
	normalBytes, err := json.Marshal(obj)
	if err != nil {
		t.Fatalf("json.Marshal() error = %v", err)
	}
	normalStr := string(normalBytes)
	t.Logf("Normal JSON: %s", normalStr)

	if strings.Contains(normalStr, "secretJSON") && !strings.Contains(normalStr, "sha256") {
		t.Errorf("Normal JSON serialization leaked raw value")
	}

	// PlaintextReplacer serialization (should expose)
	plainObj := PlaintextReplacer(obj)
	plainBytes, err := json.Marshal(plainObj)
	if err != nil {
		t.Fatalf("json.Marshal(PlaintextReplacer) error = %v", err)
	}
	plainStr := string(plainBytes)
	t.Logf("Plaintext JSON: %s", plainStr)

	if !strings.Contains(plainStr, "secretJSON") {
		t.Errorf("PlaintextReplacer JSON should include password raw value")
	}

	if !strings.Contains(plainStr, "secretNestedJSON") {
		t.Errorf("PlaintextReplacer JSON should include nested apiKey raw value")
	}

	if !strings.Contains(plainStr, "secretInArray") {
		t.Errorf("PlaintextReplacer JSON should include array secret raw value")
	}

	if strings.Contains(plainStr, "sha256:") {
		t.Errorf("PlaintextReplacer JSON should NOT contain sha256 hash")
	}
}

// TestPlaintextReplacer_Nil verifies PlaintextReplacer handles nil correctly
func TestPlaintextReplacer_Nil(t *testing.T) {
	var ss *SensitiveString
	result := PlaintextReplacer(ss)
	if result != nil {
		t.Errorf("PlaintextReplacer(nil SensitiveString) = %v, want nil", result)
	}

	result = PlaintextReplacer(nil)
	if result != nil {
		t.Errorf("PlaintextReplacer(nil) = %v, want nil", result)
	}
}
