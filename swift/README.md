# SensitiveString - Swift Implementation

A Swift implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Status

✅ **Complete and Tested** - The Swift implementation is production-ready with full protocol support and all 18 tests passing.

## Features

- 🔒 **Automatic hash display** - Shows SHA256 hash via `CustomStringConvertible`
- 📝 **Logging safe** - Works with `print()`, string interpolation, and all logging frameworks
- 🎨 **Codable integration** - One protocol = works with JSON, PropertyList, and all encoders
- ⚡ **Value semantics** - Struct-based, safe to copy and pass around
- 🧪 **Type safe** - Swift's type system ensures correct usage
- 💎 **String literal support** - Can initialize directly from string literals

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/earlye/sensitive-strings", from: "1.0.0")
]
```

Or in Xcode: File → Add Package Dependencies → paste the repository URL

### Requirements

- Swift 5.9+
- macOS 13+, iOS 16+, tvOS 16+, watchOS 9+ (for CryptoKit)

## Basic Usage

```swift
import SensitiveString

// Create a sensitive string
let password = SensitiveString("my-secret-password")

// String literal initialization
let apiKey: SensitiveString = "sk-1234567890abcdef"

// Safe operations - these all show the hash
print(password)  // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
print("\(password)")  // String interpolation - also shows hash
debugPrint(password)  // SensitiveString(sha256:...)

// Intentional access when you actually need the plaintext
let actualPassword = password.value  // or password.getValue()
```

## Logging

Works automatically with all logging approaches:

```swift
import os.log

let password = SensitiveString("secret123")

// Standard print
print("Password: \(password)")  // Shows hash ✅

// String interpolation
let message = "User password: \(password)"  // Shows hash ✅

// os_log / Logger
let logger = Logger()
logger.info("Password: \(password)")  // Shows hash ✅

// NSLog
NSLog("Password: %@", password.description)  // Shows hash ✅
```

## Serialization with Codable

The `Codable` protocol is implemented, which means it works automatically with **all** Swift encoders:

### JSON (JSONEncoder)

```swift
import Foundation

struct Credentials: Codable {
    let username: String
    let password: SensitiveString
}

let creds = Credentials(
    username: "user@example.com",
    password: SensitiveString("secret123")
)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted
let jsonData = try encoder.encode(creds)

// {
//   "username": "user@example.com",
//   "password": "sha256:..."
// }
```

### Property Lists (PropertyListEncoder)

```swift
let plistEncoder = PropertyListEncoder()
plistEncoder.outputFormat = .xml
let plistData = try plistEncoder.encode(creds)

// <?xml version="1.0" encoding="UTF-8"?>
// <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" ...>
// <plist version="1.0">
// <dict>
//     <key>username</key>
//     <string>user@example.com</string>
//     <key>password</key>
//     <string>sha256:...</string>
// </dict>
// </plist>
```

### Other Encoders

Works with any Swift encoder implementation:
- Custom binary encoders
- MessagePack encoders
- YAML encoders (via third-party packages)
- Any `Encoder` conforming type

## Plaintext Serialization

When you explicitly need to serialize the plaintext value (e.g., sending credentials to an authentication API), access the `.value` property before encoding:

```swift
struct AuthRequest: Codable {
    let username: String
    let password: String  // Plain String type
}

let sensitivePassword = SensitiveString("secret123")

// Convert to plaintext for API request
let request = AuthRequest(
    username: "user",
    password: sensitivePassword.value  // Explicit access
)

let jsonData = try JSONEncoder().encode(request)
// Now password will be plaintext in JSON
```

## API Reference

### Creating a SensitiveString

```swift
// From String
let s1 = SensitiveString("secret")

// String literal
let s2: SensitiveString = "secret"

// Using the helper
let s3 = SensitiveString.sensitive("secret")
```

### Accessing the Plaintext

```swift
let secret = SensitiveString("password")

// Property access (preferred)
let plaintext = secret.value

// Method call (API compatibility)
let plaintext = secret.getValue()
```

### Utility Properties

```swift
let secret = SensitiveString("12345")

secret.count      // Returns 5
secret.isEmpty    // Returns false

// Equality comparison
let secret2 = SensitiveString("12345")
secret == secret2  // true

// Hashable - can use in Sets and as Dictionary keys
var set = Set<SensitiveString>()
set.insert(secret)

var dict = [SensitiveString: String]()
dict[secret] = "metadata"
```

### Helper Functions

```swift
// Check if value is a SensitiveString
SensitiveString.isSensitiveString(secret)  // true

// Extract value from String or SensitiveString
SensitiveString.extractValue(secret)  // Optional<String>

// Extract value or throw
try SensitiveString.extractRequiredValue(secret)  // String

// Convert to SensitiveString
SensitiveString.sensitive("plain")  // Optional<SensitiveString>
```

## Design Philosophy

Following the pattern from the TypeScript, Go, Python, and Rust implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit property/method to get plaintext when needed
3. **Framework integration** - Work seamlessly with Swift's protocol system
4. **Consistent hashing** - Always show `sha256:<hex>` format for debugging
5. **Value semantics** - Immutable struct, safe to copy

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `.value` or `.getValue()` - this is the intended escape hatch
- Memory dumps or debugger inspection
- Reflection that reads private properties
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or serialized output - not to provide cryptographic security.

## Comparison with Other Implementations

| Feature | This Package |
|---------|-------------|
| String display | ✅ Via `CustomStringConvertible` |
| Debug printing | ✅ Via `CustomDebugStringConvertible` |
| JSON encoding | ✅ Via `Codable` |
| PropertyList encoding | ✅ Via `Codable` |
| All encoders | ✅ Via `Codable` protocol |
| String literals | ✅ Via `ExpressibleByStringLiteral` |
| Logging frameworks | ✅ Automatic |
| Type safety | ✅ Compile-time |
| Value semantics | ✅ Yes |

## Testing

Run tests using Swift Package Manager:

```bash
# Run all tests (18 tests pass)
swift test

# Run tests with verbose output
swift test --verbose

# Build without testing
swift build
```

Or in Xcode:
- Open `Package.swift`
- Press `⌘U` to run tests

**Test Results**: ✅ All 18 tests passing

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

