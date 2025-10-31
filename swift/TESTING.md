# Testing the Swift Implementation

## Prerequisites

The package requires Swift 5.7+ and compatible SDK.

### Fixing Toolchain Issues

If you see errors like "this SDK is not supported by the compiler", you have a version mismatch between your Swift compiler and SDK. To fix:

**Option 1: Update Command Line Tools (Recommended)**
```bash
# Check current version
xcode-select -p

# If using CLT, update them
sudo rm -rf /Library/Developer/CommandLineTools
sudo xcode-select --install
```

**Option 2: Use Xcode's toolchain**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**Option 3: Check Xcode installation**
- Open Xcode
- Go to Xcode → Settings → Locations
- Ensure "Command Line Tools" is set to your Xcode version

## Running Tests

From the `swift/` directory:

```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Build without testing
swift build

# Clean build
swift package clean
```

### Using Xcode

1. Open Package.swift in Xcode
2. Press `⌘U` to run tests
3. Or use Product → Test

## Manual Testing

If you can't get the test suite running due to toolchain issues, you can test manually:

```bash
cd swift
swift build
swift run
```

Or create a simple test file:

```swift
// test.swift
import Foundation
import CryptoKit

struct SensitiveString {
    private let _value: String
    
    init(_ value: String) {
        self._value = value
    }
    
    var value: String { _value }
    
    var description: String {
        let data = Data(_value.utf8)
        let hash = SHA256.hash(data: data)
        return "sha256:" + hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Test it
let password = SensitiveString("secret123")
print("Hash: \(password.description)")
print("Value: \(password.value)")
assert(!password.description.contains("secret123"))
assert(password.value == "secret123")
print("✅ Tests passed!")
```

Run with:
```bash
swift test.swift
```

## Expected Test Results

All tests should pass:
- String representation tests (shows hash)
- Debug representation tests (shows hash)
- Value access tests (returns plaintext)
- Utility tests (count, isEmpty, equality)
- Codable tests (JSON, PropertyList encoding)

The implementation includes 18 tests covering core functionality and serialization.

## Troubleshooting

### "SDK is not supported by the compiler"

Your Swift compiler version doesn't match your SDK. See "Fixing Toolchain Issues" above.

### "Module 'Foundation' not found"

Ensure you have Xcode or Command Line Tools installed:
```bash
xcode-select --install
```

### Tests fail with CryptoKit errors

CryptoKit requires specific platform versions:
- macOS 12+
- iOS 15+
- tvOS 15+
- watchOS 8+

Ensure your deployment target meets these requirements in Package.swift.

