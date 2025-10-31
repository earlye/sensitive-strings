# SensitiveString - Rust Implementation

A Rust implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Features

- 🔒 **Automatic hash display** - Shows SHA256 hash in all string contexts
- 📝 **Logging safe** - Works with all Rust logging frameworks
- 🎨 **Serde integration** - One `Serialize` implementation works with JSON, YAML, TOML, and all serde formats
- ⚡ **Zero runtime overhead** - Compile-time guarantees with trait-based design
- 🧪 **Type safe** - Rust's type system ensures correct usage

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
sensitive-string = "0.1.0"
```

Or use cargo add:

```bash
cargo add sensitive-string
```

### Features

- `serde` (enabled by default) - Adds `Serialize` implementation for all serde formats

To disable serde:

```toml
[dependencies]
sensitive-string = { version = "0.1.0", default-features = false }
```

## Basic Usage

```rust
use sensitive_string::SensitiveString;

// Create a sensitive string
let password = SensitiveString::new("my-secret-password".to_string());

// Or use .into() for convenience
let password: SensitiveString = "my-secret-password".into();

// Safe operations - these all show the hash
println!("{}", password);   // sha256:2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824
println!("{:?}", password); // SensitiveString(sha256:...)

// Intentional access when you actually need the plaintext
let actual_password = password.get_value();  // or password.value()
```

## Logging

Works automatically with all Rust logging frameworks that use the `Display` or `Debug` traits:

```rust
use log::info;
use sensitive_string::SensitiveString;

let password = SensitiveString::new("secret123".to_string());

info!("Password: {}", password);     // Shows hash ✅
info!("Password: {:?}", password);   // Shows hash ✅
```

Works with:
- `log` + `env_logger`
- `tracing`
- `slog`
- Any logger that formats via `Display` or `Debug`

## Serialization with Serde

The `Serialize` trait is implemented for `SensitiveString`, which means it works automatically with **all** serde-based formats:

### JSON (serde_json)

```rust
use sensitive_string::SensitiveString;
use serde::Serialize;

#[derive(Serialize)]
struct Credentials {
    username: String,
    password: SensitiveString,
}

let creds = Credentials {
    username: "user@example.com".to_string(),
    password: SensitiveString::new("secret123".to_string()),
};

let json = serde_json::to_string(&creds)?;
// {"username":"user@example.com","password":"sha256:..."}
```

### YAML (serde_yaml)

```rust
let yaml = serde_yaml::to_string(&creds)?;
// username: user@example.com
// password: sha256:...
```

### TOML (toml)

```rust
let toml_str = toml::to_string(&creds)?;
// username = "user@example.com"
// password = "sha256:..."
```

### Other Formats

Works with any serde-compatible format:
- MessagePack (`rmp-serde`)
- BSON (`bson`)
- CBOR (`serde_cbor`)
- Pickle (`serde-pickle`)
- XML (`serde-xml-rs`)
- And many more!

## Plaintext Serialization

When you explicitly need to serialize the plaintext value (e.g., sending credentials to an authentication API), use a custom serialization function:

```rust
use sensitive_string::SensitiveString;
use serde::{Serialize, Serializer};

fn serialize_plaintext<S>(value: &SensitiveString, serializer: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    serializer.serialize_str(value.get_value())
}

#[derive(Serialize)]
struct AuthRequest {
    username: String,
    #[serde(serialize_with = "serialize_plaintext")]
    password: SensitiveString,
}
```

## API Reference

### Creating a SensitiveString

```rust
// From String
let s1 = SensitiveString::new("secret".to_string());

// From &str
let s2 = SensitiveString::from_str("secret");

// Using Into trait
let s3: SensitiveString = "secret".into();
let s4: SensitiveString = "secret".to_string().into();

// Using the helper
let s5 = SensitiveString::sensitive("secret");
```

### Accessing the Plaintext

```rust
let secret = SensitiveString::new("password".to_string());

// Method call
let plaintext = secret.get_value();  // Returns &str

// Alternative method
let plaintext = secret.value();      // Returns &str
```

### Utility Methods

```rust
let secret = SensitiveString::new("12345".to_string());

secret.len();        // Returns 5
secret.is_empty();   // Returns false

// Equality comparison
let secret2 = SensitiveString::new("12345".to_string());
assert_eq!(secret, secret2);

// Clone
let cloned = secret.clone();
```

### Helper Functions

```rust
// Extract value from SensitiveString
SensitiveString::extract_value(&secret);  // Returns &str

// Extract value from String (for API compatibility)
SensitiveString::extract_value_from_string("plain");  // Returns &str
```

## Design Philosophy

Following the pattern from the TypeScript, Go, and Python implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit methods to get plaintext when needed
3. **Framework integration** - Work seamlessly with Rust's ecosystem via traits
4. **Consistent hashing** - Always show `sha256:<hex>` format for debugging
5. **Zero cost** - No runtime overhead compared to manual implementations

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `.value()` or `.get_value()` - this is the intended escape hatch
- Memory dumps or debugger inspection
- Unsafe code that reads memory directly
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or serialized output - not to provide cryptographic security.

## Comparison with Other Implementations

| Feature | This Crate |
|---------|-----------|
| String formatting | ✅ Via `Display` trait |
| Debug printing | ✅ Via `Debug` trait |
| JSON serialization | ✅ Via `Serialize` trait |
| YAML serialization | ✅ Via `Serialize` trait |
| TOML serialization | ✅ Via `Serialize` trait |
| All serde formats | ✅ Via `Serialize` trait |
| Logging frameworks | ✅ Automatic |
| One impl, all formats | ✅ Yes! |
| Type safety | ✅ Compile-time |
| Zero overhead | ✅ Yes |

## Testing

Run the test suite:

```bash
cargo test
```

Run tests with output:

```bash
cargo test -- --nocapture
```

Run examples:

```bash
cargo run --example basic
cargo run --example serialization
```

## Examples

See the `examples/` directory for more usage examples:

- `basic.rs` - Basic usage and formatting
- `serialization.rs` - JSON, YAML, and TOML serialization

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

