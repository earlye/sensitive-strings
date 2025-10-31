//! Serialization example with JSON, YAML, and TOML
//!
//! Run with: cargo run --example serialization

use sensitive_string::SensitiveString;
use serde::Serialize;

#[derive(Serialize)]
struct Credentials {
    username: String,
    password: SensitiveString,
    api_key: SensitiveString,
}

fn main() {
    println!("=== SensitiveString Serialization ===\n");

    let creds = Credentials {
        username: "user@example.com".to_string(),
        password: SensitiveString::new("super-secret-password".to_string()),
        api_key: SensitiveString::new("sk-1234567890abcdef".to_string()),
    };

    // JSON serialization
    println!("=== JSON (serde_json) ===");
    let json = serde_json::to_string_pretty(&creds).unwrap();
    println!("{}\n", json);

    // YAML serialization
    println!("=== YAML (serde_yaml) ===");
    let yaml = serde_yaml::to_string(&creds).unwrap();
    println!("{}", yaml);

    // TOML serialization
    println!("=== TOML (toml) ===");
    let toml_str = toml::to_string(&creds).unwrap();
    println!("{}", toml_str);

    println!("\n✅ Notice: All formats show SHA256 hashes, not plaintext!");
}

