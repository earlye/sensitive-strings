//! Basic usage example of SensitiveString
//!
//! Run with: cargo run --example basic

use sensitive_string::SensitiveString;

fn main() {
    println!("=== Basic SensitiveString Usage ===\n");

    // Create a sensitive string
    let password = SensitiveString::new("my-secret-password".to_string());

    // Display formatting - shows hash
    println!("Display format: {}", password);
    println!("Debug format: {:?}", password);

    // Can also use .into() for convenience
    let api_key: SensitiveString = "sk-1234567890abcdef".into();
    println!("\nAPI Key: {}", api_key);

    // Intentional access when you need the plaintext
    println!("\n=== Intentional Access ===");
    println!("Plaintext (via get_value): {}", password.get_value());
    println!("Plaintext (via value): {}", password.value());

    // Utility methods
    println!("\n=== Utility Methods ===");
    println!("Length: {}", password.len());
    println!("Is empty: {}", password.is_empty());

    // Equality
    let password2 = SensitiveString::new("my-secret-password".to_string());
    println!("Equal to copy: {}", password == password2);

    // Clone
    let cloned = password.clone();
    println!("Equal to clone: {}", password == cloned);

    // String concatenation - shows hash
    println!("\n=== String Operations ===");
    let message = format!("Your password is: {}", password);
    println!("{}", message);
}

