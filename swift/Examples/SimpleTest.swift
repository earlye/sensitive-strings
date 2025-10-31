#!/usr/bin/env swift

// Simple standalone test that doesn't require the package system
// Run with: swift Examples/SimpleTest.swift

import Foundation
import CryptoKit

struct SensitiveString: CustomStringConvertible, CustomDebugStringConvertible, Equatable, Hashable {
    private let _value: String
    
    init(_ value: String) {
        self._value = value
    }
    
    var value: String {
        return _value
    }
    
    var description: String {
        let data = Data(_value.utf8)
        let hash = SHA256.hash(data: data)
        return "sha256:" + hash.map { String(format: "%02x", $0) }.joined()
    }
    
    var debugDescription: String {
        return "SensitiveString(\(description))"
    }
    
    var count: Int {
        return _value.count
    }
    
    var isEmpty: Bool {
        return _value.isEmpty
    }
}

// Test it!
print("=== SensitiveString Simple Tests ===\n")

// Test 1: String representation shows hash
let password = SensitiveString("my-secret-password")
print("Test 1: String representation")
print("  Result: \(password)")
assert(password.description.hasPrefix("sha256:"))
assert(!password.description.contains("my-secret-password"))
print("  ✅ Shows hash, not plaintext\n")

// Test 2: Debug representation shows hash
print("Test 2: Debug representation")
print("  Result: \(password.debugDescription)")
assert(password.debugDescription.hasPrefix("SensitiveString(sha256:"))
print("  ✅ Debug shows hash\n")

// Test 3: Value access returns plaintext
print("Test 3: Value access")
assert(password.value == "my-secret-password")
print("  ✅ Can access plaintext via .value\n")

// Test 4: String interpolation shows hash
print("Test 4: String interpolation")
let message = "Password: \(password)"
assert(message.contains("sha256:"))
assert(!message.contains("my-secret-password"))
print("  Result: \(message)")
print("  ✅ Interpolation shows hash\n")

// Test 5: Equality
print("Test 5: Equality")
let password2 = SensitiveString("my-secret-password")
let password3 = SensitiveString("different")
assert(password == password2)
assert(password != password3)
print("  ✅ Equality works\n")

// Test 6: Hashable (can use in Set)
print("Test 6: Hashable")
var set = Set<SensitiveString>()
set.insert(password)
set.insert(password2)  // Same value
set.insert(password3)  // Different value
assert(set.count == 2)  // Should have 2 unique values
print("  ✅ Can use in Set\n")

// Test 7: Utility properties
print("Test 7: Utility properties")
let short = SensitiveString("12345")
assert(short.count == 5)
assert(!short.isEmpty)
let empty = SensitiveString("")
assert(empty.isEmpty)
print("  ✅ count and isEmpty work\n")

// Test 8: JSON-like encoding (manual)
print("Test 8: JSON encoding simulation")
struct Credentials {
    let username: String
    let password: SensitiveString
    
    func toJSON() -> String {
        return """
        {
          "username": "\(username)",
          "password": "\(password)"
        }
        """
    }
}

let creds = Credentials(username: "user@example.com", password: password)
let json = creds.toJSON()
print("  Result:")
print(json)
assert(json.contains("user@example.com"))
assert(json.contains("sha256:"))
assert(!json.contains("my-secret-password"))
print("  ✅ JSON encoding shows hash\n")

print("=== All Tests Passed! ✅ ===")

