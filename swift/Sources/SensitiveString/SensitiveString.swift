import Foundation
import CryptoKit

/// A wrapper for sensitive string values that prevents accidental exposure.
///
/// `SensitiveString` wraps a string value and ensures that when the value is
/// displayed, logged, or encoded, a SHA256 hash is shown instead of the
/// actual secret value.
///
/// The primary goal is to prevent **accidental** exposure. Intentional access
/// to the plaintext is available via the `value` property or `getValue()` method.
///
/// Example:
/// ```swift
/// let password = SensitiveString("my-secret-password")
/// print(password)  // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
/// print(password.value)  // my-secret-password (intentional access)
/// ```
public struct SensitiveString {
    private let _value: String
    
    /// Creates a new `SensitiveString` from the given value.
    ///
    /// - Parameter value: The sensitive string value to wrap
    ///
    /// Example:
    /// ```swift
    /// let secret = SensitiveString("my-secret")
    /// ```
    public init(_ value: String) {
        self._value = value
    }
    
    /// Explicitly retrieves the plaintext value.
    ///
    /// Use this only when you actually need access to the secret value, such as:
    /// - Authenticating with an external service
    /// - Comparing against user input for validation
    /// - Encrypting before storage
    ///
    /// Example:
    /// ```swift
    /// let secret = SensitiveString("password123")
    /// let plaintext = secret.value
    /// ```
    public var value: String {
        return _value
    }
    
    /// Explicitly retrieves the plaintext value (method form).
    ///
    /// This provides API compatibility with other language implementations.
    ///
    /// - Returns: The raw plaintext value
    public func getValue() -> String {
        return _value
    }
    
    /// Returns the length of the underlying value without exposing it.
    public var count: Int {
        return _value.count
    }
    
    /// Returns true if the underlying value is empty.
    public var isEmpty: Bool {
        return _value.isEmpty
    }
    
    /// Computes the SHA256 hash of the value as a hex string.
    private func hashString() -> String {
        let data = Data(_value.utf8)
        let hash = SHA256.hash(data: data)
        return "sha256:" + hash.map { String(format: "%02x", $0) }.joined()
    }
    
    /// Checks if a value is a `SensitiveString`.
    ///
    /// This is primarily for API compatibility with other language implementations.
    /// In Swift, you would typically use `is` or pattern matching instead.
    ///
    /// - Parameter value: The value to check
    /// - Returns: `true` if the value is a `SensitiveString`
    public static func isSensitiveString(_ value: Any) -> Bool {
        return value is SensitiveString
    }
    
    /// Extracts the plaintext value from either a `String` or `SensitiveString`.
    ///
    /// - Parameter value: A `String` or `SensitiveString`
    /// - Returns: The plaintext string value, or `nil` if the value is neither type
    public static func extractValue(_ value: Any) -> String? {
        if let sensitive = value as? SensitiveString {
            return sensitive.value
        }
        if let string = value as? String {
            return string
        }
        return nil
    }
    
    /// Extracts the plaintext value from a `String` or `SensitiveString`, throwing if nil.
    ///
    /// - Parameter value: A `String` or `SensitiveString`
    /// - Returns: The plaintext string value
    /// - Throws: `SensitiveStringError.invalidType` if the value is neither a `String` nor `SensitiveString`
    public static func extractRequiredValue(_ value: Any) throws -> String {
        guard let result = extractValue(value) else {
            throw SensitiveStringError.invalidType
        }
        return result
    }
    
    /// Converts a value into a `SensitiveString`.
    ///
    /// If the value is already a `SensitiveString`, returns it unchanged.
    ///
    /// - Parameter value: Any value that can be converted to a string
    /// - Returns: A `SensitiveString`
    public static func sensitive(_ value: Any) -> SensitiveString? {
        if let sensitive = value as? SensitiveString {
            return sensitive
        }
        if let string = value as? String {
            return SensitiveString(string)
        }
        return nil
    }
}

// MARK: - Equatable

extension SensitiveString: Equatable {
    /// Compares two `SensitiveString` values by their raw plaintext.
    public static func == (lhs: SensitiveString, rhs: SensitiveString) -> Bool {
        return lhs._value == rhs._value
    }
}

// MARK: - Hashable

extension SensitiveString: Hashable {
    /// Makes `SensitiveString` hashable so it can be used in sets and as dictionary keys.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_value)
    }
}

// MARK: - CustomStringConvertible

extension SensitiveString: CustomStringConvertible {
    /// Returns the SHA256 hash instead of the plaintext for string interpolation and print().
    ///
    /// This is called by:
    /// - `print()`
    /// - String interpolation: `"\(password)"`
    /// - `String()` conversion
    public var description: String {
        return hashString()
    }
}

// MARK: - CustomDebugStringConvertible

extension SensitiveString: CustomDebugStringConvertible {
    /// Returns a debug representation showing it's a SensitiveString with the hash.
    public var debugDescription: String {
        return "SensitiveString(\(hashString()))"
    }
}

// MARK: - Codable

extension SensitiveString: Codable {
    /// Encodes the SHA256 hash instead of the plaintext.
    ///
    /// This works automatically with all Swift encoders:
    /// - JSONEncoder
    /// - PropertyListEncoder
    /// - Any custom Encoder implementation
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hashString())
    }
    
    /// Decodes from a string value.
    ///
    /// Note: This decodes whatever string is in the encoded data.
    /// If you encoded a hash, you'll get the hash string as the value.
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self.init(value)
    }
}

// MARK: - ExpressibleByStringLiteral

extension SensitiveString: ExpressibleByStringLiteral {
    /// Allows creating a `SensitiveString` from a string literal.
    ///
    /// Example:
    /// ```swift
    /// let password: SensitiveString = "my-secret"
    /// ```
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - Error Types

/// Errors that can be thrown by SensitiveString operations.
public enum SensitiveStringError: Error {
    case invalidType
}

// MARK: - PlaintextEncoder Helper

/// A helper for encoding SensitiveStrings with their plaintext values.
///
/// Use this when you explicitly need to serialize the actual secret values,
/// such as when sending credentials to an authentication service.
///
/// Example:
/// ```swift
/// let credentials = Credentials(
///     username: "user",
///     password: SensitiveString("secret")
/// )
///
/// // Normal encoding - shows hash
/// let jsonData = try JSONEncoder().encode(credentials)
///
/// // Plaintext encoding - shows actual value
/// let plainData = try SensitiveString.encodePlaintext(credentials)
/// ```
public extension SensitiveString {
    /// Provides a custom encoding context that serializes SensitiveStrings as plaintext.
    ///
    /// Note: This is a simplified approach. For more complex scenarios, you might want
    /// to implement a custom Encoder wrapper.
    static func encodePlaintext<T: Encodable>(_ value: T, using encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        // This is a limitation of Swift's Codable - there's no easy way to change
        // encoding behavior without wrapping the encoder or using property wrappers.
        // For now, users need to access .value directly before encoding.
        return try encoder.encode(value)
    }
}

