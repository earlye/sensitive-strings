//! SensitiveString - A wrapper for sensitive string values that prevents accidental exposure.
//!
//! This crate provides a `SensitiveString` type that wraps sensitive values (like passwords,
//! API keys, tokens) and returns a SHA256 hash instead of the raw value when formatted,
//! logged, or serialized.
//!
//! # Example
//!
//! ```
//! use sensitive_string::SensitiveString;
//!
//! let password = SensitiveString::new("my-secret-password".to_string());
//!
//! // Safe operations - these all show the hash
//! println!("{}", password);  // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
//! println!("{:?}", password); // SensitiveString(sha256:...)
//!
//! // Intentional access when you actually need the plaintext
//! let actual_password = password.get_value();
//! ```
//!
//! # Serialization
//!
//! With the `serde` feature (enabled by default), `SensitiveString` implements `Serialize`
//! and works automatically with all serde-based formats (JSON, YAML, TOML, etc.):
//!
//! ```
//! # #[cfg(feature = "serde")]
//! # {
//! use sensitive_string::SensitiveString;
//! use serde::Serialize;
//!
//! #[derive(Serialize)]
//! struct Credentials {
//!     username: String,
//!     password: SensitiveString,
//! }
//!
//! let creds = Credentials {
//!     username: "user@example.com".to_string(),
//!     password: SensitiveString::new("secret123".to_string()),
//! };
//!
//! let json = serde_json::to_string(&creds).unwrap();
//! // {"username":"user@example.com","password":"sha256:..."}
//! # }
//! ```

use sha2::{Digest, Sha256};
use std::fmt;

/// A wrapper for sensitive string values that prevents accidental exposure.
///
/// `SensitiveString` wraps a string value and ensures that when the value is
/// displayed, logged, or serialized, a SHA256 hash is shown instead of the
/// actual secret value.
///
/// The primary goal is to prevent **accidental** exposure. Intentional access
/// to the plaintext is available via `get_value()` or `value()` methods.
#[derive(Clone, PartialEq, Eq, Hash)]
pub struct SensitiveString {
    value: String,
}

impl SensitiveString {
    /// Creates a new `SensitiveString` from the given value.
    ///
    /// # Example
    ///
    /// ```
    /// use sensitive_string::SensitiveString;
    ///
    /// let secret = SensitiveString::new("my-secret".to_string());
    /// ```
    pub fn new(value: String) -> Self {
        Self { value }
    }

    /// Creates a new `SensitiveString` from a string slice.
    ///
    /// # Example
    ///
    /// ```
    /// use sensitive_string::SensitiveString;
    ///
    /// let secret = SensitiveString::from_str("my-secret");
    /// ```
    pub fn from_str(value: &str) -> Self {
        Self {
            value: value.to_string(),
        }
    }

    /// Explicitly retrieves the plaintext value.
    ///
    /// Use this only when you actually need access to the secret value, such as:
    /// - Authenticating with an external service
    /// - Comparing against user input for validation
    /// - Encrypting before storage
    ///
    /// # Example
    ///
    /// ```
    /// use sensitive_string::SensitiveString;
    ///
    /// let secret = SensitiveString::new("password123".to_string());
    /// let plaintext = secret.get_value();
    /// assert_eq!(plaintext, "password123");
    /// ```
    pub fn get_value(&self) -> &str {
        &self.value
    }

    /// Explicitly retrieves the plaintext value (alias for `get_value`).
    ///
    /// This provides a more natural API for some use cases.
    pub fn value(&self) -> &str {
        &self.value
    }

    /// Returns the length of the underlying value without exposing it.
    ///
    /// # Example
    ///
    /// ```
    /// use sensitive_string::SensitiveString;
    ///
    /// let secret = SensitiveString::new("12345".to_string());
    /// assert_eq!(secret.len(), 5);
    /// ```
    pub fn len(&self) -> usize {
        self.value.len()
    }

    /// Returns true if the underlying value is empty.
    pub fn is_empty(&self) -> bool {
        self.value.is_empty()
    }

    /// Computes the SHA256 hash of the value as a hex string.
    fn hash_string(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.value.as_bytes());
        let result = hasher.finalize();
        format!("sha256:{}", hex::encode(result))
    }

    /// Checks if an object is a `SensitiveString`.
    ///
    /// This is primarily for API compatibility with other language implementations.
    /// In Rust, you would typically use pattern matching or type checking instead.
    pub fn is_sensitive_string<T>(_value: &T) -> bool
    where
        T: ?Sized + 'static,
    {
        std::any::TypeId::of::<T>() == std::any::TypeId::of::<Self>()
    }

    /// Extracts the plaintext value from either a `String` or `SensitiveString`.
    ///
    /// This is useful when you have an API that accepts either type.
    pub fn extract_value_from_string(value: &str) -> &str {
        value
    }

    /// Extracts the plaintext value from a `SensitiveString`.
    pub fn extract_value(value: &SensitiveString) -> &str {
        value.get_value()
    }

    /// Converts a value into a `SensitiveString`.
    ///
    /// If the value is already a `SensitiveString`, it returns it unchanged.
    pub fn sensitive(value: impl Into<String>) -> Self {
        Self::new(value.into())
    }
}

/// Implements `Display` for use with `println!`, `format!`, logging, etc.
///
/// Returns the SHA256 hash instead of the plaintext to prevent accidental exposure.
impl fmt::Display for SensitiveString {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.hash_string())
    }
}

/// Implements `Debug` for use with `{:?}` formatting.
///
/// Returns a debug representation showing the hash, not the plaintext.
impl fmt::Debug for SensitiveString {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "SensitiveString({})", self.hash_string())
    }
}

/// Implements `From<String>` for convenient conversion.
impl From<String> for SensitiveString {
    fn from(value: String) -> Self {
        Self::new(value)
    }
}

/// Implements `From<&str>` for convenient conversion.
impl From<&str> for SensitiveString {
    fn from(value: &str) -> Self {
        Self::from_str(value)
    }
}

#[cfg(feature = "serde")]
mod serde_impl {
    use super::SensitiveString;
    use serde::{Serialize, Serializer};

    /// Implements `Serialize` to work with all serde-based formats.
    ///
    /// This serializes the SHA256 hash instead of the plaintext, preventing
    /// accidental exposure in JSON, YAML, TOML, and other formats.
    impl Serialize for SensitiveString {
        fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
        where
            S: Serializer,
        {
            serializer.serialize_str(&self.hash_string())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_display_shows_hash() {
        let secret = SensitiveString::new("my-secret-value".to_string());
        let result = format!("{}", secret);

        assert!(result.starts_with("sha256:"));
        assert!(!result.contains("my-secret-value"));
        assert_eq!(result.len(), 71); // "sha256:" (7) + 64 hex chars
    }

    #[test]
    fn test_debug_shows_hash() {
        let secret = SensitiveString::new("my-secret-value".to_string());
        let result = format!("{:?}", secret);

        assert!(result.starts_with("SensitiveString(sha256:"));
        assert!(!result.contains("my-secret-value"));
    }

    #[test]
    fn test_get_value_returns_plaintext() {
        let secret = SensitiveString::new("my-secret-value".to_string());
        assert_eq!(secret.get_value(), "my-secret-value");
    }

    #[test]
    fn test_value_returns_plaintext() {
        let secret = SensitiveString::new("my-secret-value".to_string());
        assert_eq!(secret.value(), "my-secret-value");
    }

    #[test]
    fn test_len() {
        let secret = SensitiveString::new("12345".to_string());
        assert_eq!(secret.len(), 5);
    }

    #[test]
    fn test_is_empty() {
        let empty = SensitiveString::new("".to_string());
        let not_empty = SensitiveString::new("value".to_string());

        assert!(empty.is_empty());
        assert!(!not_empty.is_empty());
    }

    #[test]
    fn test_equality() {
        let secret1 = SensitiveString::new("same-value".to_string());
        let secret2 = SensitiveString::new("same-value".to_string());
        let secret3 = SensitiveString::new("different-value".to_string());

        assert_eq!(secret1, secret2);
        assert_ne!(secret1, secret3);
    }

    #[test]
    fn test_clone() {
        let secret1 = SensitiveString::new("value".to_string());
        let secret2 = secret1.clone();

        assert_eq!(secret1, secret2);
    }

    #[test]
    fn test_consistent_hash() {
        let secret1 = SensitiveString::new("consistent-value".to_string());
        let secret2 = SensitiveString::new("consistent-value".to_string());

        assert_eq!(format!("{}", secret1), format!("{}", secret2));
    }

    #[test]
    fn test_from_string() {
        let secret: SensitiveString = "my-secret".to_string().into();
        assert_eq!(secret.get_value(), "my-secret");
    }

    #[test]
    fn test_from_str() {
        let secret: SensitiveString = "my-secret".into();
        assert_eq!(secret.get_value(), "my-secret");
    }

    #[test]
    fn test_extract_value() {
        let secret = SensitiveString::new("secret".to_string());
        assert_eq!(SensitiveString::extract_value(&secret), "secret");
    }

    #[test]
    fn test_sensitive() {
        let secret = SensitiveString::sensitive("plain");
        assert_eq!(secret.get_value(), "plain");
    }

    #[cfg(feature = "serde")]
    mod serde_tests {
        use super::*;
        use serde::Serialize;

        #[test]
        fn test_json_serialization() {
            #[derive(Serialize)]
            struct Credentials {
                username: String,
                password: SensitiveString,
            }

            let creds = Credentials {
                username: "user@example.com".to_string(),
                password: SensitiveString::new("secret123".to_string()),
            };

            let json = serde_json::to_string(&creds).unwrap();

            assert!(json.contains("user@example.com"));
            assert!(json.contains("sha256:"));
            assert!(!json.contains("secret123"));
        }

        #[test]
        fn test_yaml_serialization() {
            #[derive(Serialize)]
            struct Config {
                api_key: SensitiveString,
            }

            let config = Config {
                api_key: SensitiveString::new("secret-api-key".to_string()),
            };

            let yaml = serde_yaml::to_string(&config).unwrap();

            assert!(yaml.contains("sha256:"));
            assert!(!yaml.contains("secret-api-key"));
        }

        #[test]
        fn test_toml_serialization() {
            #[derive(Serialize)]
            struct Settings {
                token: SensitiveString,
            }

            let settings = Settings {
                token: SensitiveString::new("my-token".to_string()),
            };

            let toml_str = toml::to_string(&settings).unwrap();

            assert!(toml_str.contains("sha256:"));
            assert!(!toml_str.contains("my-token"));
        }
    }
}

