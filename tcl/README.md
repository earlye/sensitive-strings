# SensitiveString for Tcl

A Tcl implementation of SensitiveString - a type that wraps secret values and prevents accidental exposure by returning a SHA256 hash instead of the raw value.

## Requirements

- **Tcl 9.x** (includes TclOO and the `sha256` package)

### Installing Tcl 9

**macOS (Homebrew):**
```bash
brew install tcl-tk
$(brew --prefix tcl-tk)/bin/tclsh test_sensitive_string.tcl
```

For other platforms, consult your package manager or [tcl.tk](https://www.tcl.tk/).


## Usage

```tcl
source sensitive_string.tcl

# Create a SensitiveString
set password [::sensitivestring::new "super-secret-password"]

# Safe to log - returns hash
puts [$password toString]
# Output: sha256:5e884898da28047d9806e99e69f0c7e47e20a3d463b6e982e07b50cd6d5e7e6c

# Get the actual value when needed
set plaintext [$password getValue]

# Get length without exposing value
puts "Password length: [$password length]"

# Compare two SensitiveStrings safely
set pw1 [::sensitivestring::new "secret"]
set pw2 [::sensitivestring::new "secret"]
if {[$pw1 equals $pw2]} {
    puts "Passwords match!"
}
```

## API Reference

### Creating SensitiveStrings

```tcl
# Direct creation
set ss [::sensitivestring::new "secret value"]

# Convert any input to SensitiveString (idempotent)
set ss [::sensitivestring::sensitive "secret value"]
set ss2 [::sensitivestring::sensitive $ss]  ;# Returns same object
```

### Object Methods

| Method | Description |
|--------|-------------|
| `$ss toString` | Returns SHA256 hash prefixed with "sha256:" |
| `$ss getValue` | Returns the raw plaintext value |
| `$ss length` | Returns length of underlying value |
| `$ss equals $other` | Compares hashes of two SensitiveStrings |
| `$ss toDict` | Returns a dict with the hash as value |
| `$ss destroy` | Destroys the object (cleanup) |

### Utility Functions

```tcl
# Check if something is a SensitiveString
::sensitivestring::isSensitiveString $input  ;# Returns 0 or 1

# Extract value (returns {value found} list)
lassign [::sensitivestring::extractValue $input] value found

# Extract value or error
set value [::sensitivestring::extractRequiredValue $input]

# Replace SensitiveStrings with plaintext in nested structures
# WARNING: Use only when you explicitly need to serialize secrets
set plain [::sensitivestring::plaintextReplacer $data]

# Safe logging helper - replaces SensitiveStrings with hashes
set safe [::sensitivestring::safeLog $data]
```

## TCL-Specific Considerations

### The "Everything is a String" Challenge

Tcl's philosophy treats everything as a string, which means there's no automatic `toString` hook when you do something like `puts $var`. In Tcl, you must explicitly call the method:

```tcl
# This won't show the hash - it shows the object reference
puts $password
# Output: ::oo::Obj42

# Do this instead
puts [$password toString]
# Output: sha256:5e884898da28047d...
```

### Safe Logging Pattern

For consistent safe logging, use the `safeLog` helper:

```tcl
set credentials [dict create \
    username "user@example.com" \
    password [::sensitivestring::new "secret123"]]

# Safe to log
puts [::sensitivestring::safeLog $credentials]
# Output: username user@example.com password sha256:...
```

### Working with Dicts

```tcl
# Create a dict with sensitive data
set config [dict create \
    host "localhost" \
    port 5432 \
    password [::sensitivestring::new "db-password"]]

# Safe logging (hashes sensitive values)
puts [::sensitivestring::safeLog $config]

# When you need plaintext (e.g., actual DB connection)
set plainConfig [::sensitivestring::plaintextReplacer $config]
```

## Running Tests

```bash
cd tcl
tclsh test_sensitive_string.tcl
```

Or with Homebrew Tcl on macOS:
```bash
$(brew --prefix tcl-tk)/bin/tclsh test_sensitive_string.tcl
```

Expected output:
```
======================================
SensitiveString TCL Tests
======================================

Test: Basic creation and toString
  ✓ toString returns sha256 prefixed hash
  ✓ hash has correct length (sha256: + 64 hex chars)
...
======================================
Test Summary
======================================
Passed: XX
Failed: 0
```

## Examples

### Configuration Management

```tcl
proc loadConfig {configFile} {
    # Load config, wrapping sensitive values
    set config [dict create]
    dict set config database_url "postgres://localhost/mydb"
    dict set config api_key [::sensitivestring::new "sk-1234567890"]
    dict set config jwt_secret [::sensitivestring::new "super-secret-jwt"]
    
    return $config
}

proc connectToApi {config} {
    # Safe to log the config
    puts "Connecting with config: [::sensitivestring::safeLog $config]"
    
    # Get the actual API key when needed
    set apiKey [[dict get $config api_key] getValue]
    # Use $apiKey for actual API call...
}
```

### Comparing Secrets

```tcl
proc verifyPassword {inputPassword storedPassword} {
    # Both should be SensitiveStrings
    set input [::sensitivestring::sensitive $inputPassword]
    return [$input equals $storedPassword]
}
```

## Does SensitiveString Make Sense in Tcl?

**Yes, with caveats:**

**What works well:**
- TclOO provides clean encapsulation of the secret value
- Methods control exactly how the value is exposed
- The `safeLog` helper makes it easy to safely log complex data structures

**Tcl-specific limitations:**
- No automatic `toString` - you must explicitly call `[$obj toString]`
- Tcl's "everything is a string" philosophy means the protection is more about developer discipline than language enforcement
- Object references (like `::oo::Obj42`) are still strings and could theoretically be passed around

Despite these limitations, SensitiveString provides valuable protection against the most common accidental exposure scenarios: logging, serialization, and string interpolation.

## License

See the LICENSE.md file in the root of this repository.
