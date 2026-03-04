module github.com/earlye/sensitive-strings/golang

go 1.25.3



// Deprecated: this module path contains a plaintext leak when SensitiveString
// is used as a value type in a struct logged via slog. Migrate to
// github.com/earlye/sensitive-strings/golang/ss instead.
retract (
    v1.0.3
	v1.0.2
	v1.0.1
	v1.0.0
)
