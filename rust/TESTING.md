# Testing the Rust Implementation

## Prerequisites

Install Rust if you haven't already:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Or visit [https://rustup.rs/](https://rustup.rs/)

## Running Tests

From the `rust/` directory:

```bash
# Run all tests
cargo test

# Run tests with verbose output
cargo test -- --nocapture

# Run a specific test
cargo test test_display_shows_hash

# Run only serde tests
cargo test --features serde

# Run without serde feature
cargo test --no-default-features
```

## Running Examples

```bash
# Basic usage example
cargo run --example basic

# Serialization example (JSON, YAML, TOML)
cargo run --example serialization
```

## Building

```bash
# Debug build
cargo build

# Release build (optimized)
cargo build --release

# Check without building
cargo check
```

## Code Coverage

Using tarpaulin:

```bash
cargo install cargo-tarpaulin
cargo tarpaulin --out Html
```

## Linting

```bash
# Run clippy for lints
cargo clippy

# Auto-fix issues
cargo clippy --fix

# Format code
cargo fmt
```

## Documentation

```bash
# Build and open docs
cargo doc --open

# Check doc tests
cargo test --doc
```

## Expected Test Results

All tests should pass:
- Basic display and debug formatting (hash output)
- Plaintext access via get_value() and value()
- Utility methods (len, is_empty)
- Equality and cloning
- Serde serialization for JSON, YAML, and TOML (when feature enabled)

The implementation includes 17 tests covering core functionality and serialization.

