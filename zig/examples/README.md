# Examples Directory

## Status

✅ **Working!** - The build system is properly configured for Zig 0.15.

## Running Examples

```bash
cd ..  # Go to zig/ root directory
zig build example
```

This will build and run the example, which demonstrates:
- Creating SensitiveStrings
- Automatic hash display in formatting
- JSON serialization (showing hashes)
- Intentional plaintext access

## How It Works

The build system (`../build.zig`) sets up a module called "sensitive_string" that the examples can import:

```zig
const SensitiveString = @import("sensitive_string").SensitiveString;
```

This demonstrates Zig's powerful build system with proper module management!
