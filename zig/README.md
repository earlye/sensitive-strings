## SensitiveString - Zig Implementation

A Zig implementation of SensitiveString for wrapping sensitive values (passwords, API keys, tokens) to prevent accidental exposure in logs, console output, and serialization.

## Status

✅ **Core Implementation Complete** - All 10 tests passing  
✅ **JSON Serialization** - Working with Zig 0.15!  
✅ **Build System** - Fully working with Zig 0.15!

**To test and run:**
```bash
cd zig
zig build test --summary all           # Run tests via build system ✅
zig test src/sensitive_string.zig      # Run tests (clean summary) ✅
zig test src/sensitive_string.zig | cat  # Run tests (verbose, all test names) ✅
zig build example                       # Build and run the example ✅
```

Note: Zig's test runner shows progress interactively then erases it for a clean summary. Pipe through `cat` to see all test names.

See [STATUS.md](STATUS.md) for detailed information about Zig 0.15 API changes.

## Features

- 🔒 **Automatic hash display** - Via custom `format()` method recognized by `std.fmt`
- 📝 **Logging safe** - Works with `std.debug.print`, `std.log`, and all Zig logging
- 🎨 **JSON integration** - Via custom `jsonStringify()` method recognized by `std.json`
- ⚡ **Performance** - Compiles to fast native code like C
- 🧪 **Explicit memory management** - Full control over allocations
- 💡 **Comptime features** - Leverages Zig's compile-time capabilities

## Installation

### As a Zig Module

Add to your `build.zig`:

```zig
const sensitive_string = b.dependency("sensitive-string", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("sensitive_string", sensitive_string.module("sensitive-string"));
```

### Requirements

- Zig 0.15.0 or later

## Basic Usage

```zig
const std = @import("std");
const SensitiveString = @import("sensitive_string").SensitiveString;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a sensitive string (allocates memory)
    const password = try SensitiveString.init(allocator, "my-secret-password");
    defer password.deinit(); // Don't forget to free!

    // Safe operations - these show the hash
    std.debug.print("{}\n", .{password});  // sha256:2cf24...
    std.debug.print("Password: {}\n", .{password});  // Password: sha256:...

    // Intentional access when you need the plaintext
    const plaintext = password.value;  // or password.getValue()
    std.debug.print("Plaintext: {s}\n", .{plaintext});
}
```

### Borrowed Values (No Allocation)

```zig
// Use initBorrowed() when you know the value will outlive the SensitiveString
const static_secret = "compile-time-secret";
const secret = SensitiveString.initBorrowed(static_secret);
// No deinit() needed - memory isn't owned

std.debug.print("{}\n", .{secret});  // Shows hash
```

## Logging

Zig's formatting system automatically calls the `format()` method:

```zig
const password = try SensitiveString.init(allocator, "secret123");
defer password.deinit();

// std.debug.print - shows hash ✅
std.debug.print("Password: {}\n", .{password});

// std.log - shows hash ✅
std.log.info("Password: {}", .{password});

// Custom formatters - shows hash ✅
var buffer: [256]u8 = undefined;
const formatted = try std.fmt.bufPrint(&buffer, "{}", .{password});
```

## JSON Serialization

The `jsonStringify()` method is automatically recognized by `std.json`:

```zig
const Credentials = struct {
    username: []const u8,
    password: SensitiveString,
};

const creds = Credentials{
    .username = "user@example.com",
    .password = try SensitiveString.init(allocator, "secret123"),
};
defer creds.password.deinit();

// Serialize to JSON
var buffer = std.ArrayList(u8).init(allocator);
defer buffer.deinit();

try std.json.stringify(creds, .{}, buffer.writer());
// {"username":"user@example.com","password":"sha256:..."}
```

### Pretty Printing

```zig
try std.json.stringify(creds, .{ .whitespace = .indent_2 }, buffer.writer());
// {
//   "username": "user@example.com",
//   "password": "sha256:..."
// }
```

## Memory Management

Zig requires explicit memory management. SensitiveString provides two initialization methods:

### `init()` - Owned Memory

```zig
// Copies the value - you own the memory
const secret = try SensitiveString.init(allocator, value);
defer secret.deinit(); // Required!
```

### `initBorrowed()` - Borrowed Memory

```zig
// No copy - references existing memory
const secret = SensitiveString.initBorrowed(value);
// No deinit() needed - you don't own the memory
```

## API Reference

### Creating a SensitiveString

```zig
// Owned (copies value)
const s1 = try SensitiveString.init(allocator, "secret");
defer s1.deinit();

// Borrowed (no copy)
const s2 = SensitiveString.initBorrowed("secret");

// Using helper
const s3 = try sensitive(allocator, "secret");
defer s3.deinit();
```

### Accessing the Plaintext

```zig
const secret = try SensitiveString.init(allocator, "password");
defer secret.deinit();

// Field access
const plaintext = secret.value;

// Method call (API compatibility)
const plaintext = secret.getValue();
```

### Getting the Hash

```zig
const secret = try SensitiveString.init(allocator, "password");
defer secret.deinit();

// Get hash as string (allocates)
const hash = try secret.hashHex(allocator);
defer allocator.free(hash);

std.debug.print("{s}\n", .{hash});  // sha256:5e884...
```

### Helper Functions

```zig
// Extract value from SensitiveString
const value = extractValue(secret);  // Returns []const u8

// Check type
if (SensitiveString.isSensitiveString(some_value)) {
    // Handle sensitive string
}
```

## Design Philosophy

Following the pattern from other language implementations:

1. **Accidental exposure protection** - Make the default behavior safe
2. **Intentional access available** - Provide explicit methods/fields for plaintext
3. **Convention-based integration** - Use Zig's standard conventions (`format()`, `jsonStringify()`)
4. **Consistent hashing** - Always show `sha256:<hex>` format for debugging
5. **Explicit memory management** - Clear ownership and lifecycle

## What's Intentionally NOT Protected

This library prevents **accidental** exposure. It does NOT prevent:

- Intentional access via `.value` or `.getValue()` - this is the intended escape hatch
- Memory dumps or debugger inspection
- Reading memory directly
- Side-channel attacks or timing attacks

The goal is to prevent secrets from accidentally ending up in logs, error messages, or serialized output - not to provide cryptographic security.

## Testing

Run the test suite:

```bash
# Run all tests
zig build test

# Run tests with output
zig build test --summary all

# Build only
zig build
```

Run examples:

```bash
# Run basic example
zig build example

# Or manually
zig build
./zig-out/bin/example
```

## Comparison with Other Implementations

| Feature | TypeScript | Go | Python | Rust | Swift | **Zig** |
|---------|-----------|-----|--------|------|-------|---------|
| **String formatting** | `toString()` | `String()` | `__str__()` | `Display` | `description` | **`format()` ✅** |
| **JSON serialization** | `toJSON()` ✅ | `MarshalJSON()` ✅ | ❌ No hook | `Serialize` ✅ | `Codable` ✅ | **`jsonStringify()` ✅** |
| **Convention-based** | ✅ Yes | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes | **✅ Yes** |
| **Memory management** | GC | GC | GC | Ownership | ARC | **Manual** |
| **Performance** | JIT | Native | Interpreter | Native | Native | **Native** |
| **Learning curve** | Low | Low | Low | High | Medium | **Medium-High** |

## Zig-Specific Advantages

1. **Convention-based hooks in stdlib** - `format()` and `jsonStringify()` just work
2. **No external dependencies** - Everything in the standard library
3. **Explicit control** - You decide when allocations happen
4. **Comptime features** - Can do clever compile-time validation
5. **C interop** - Easy to use from C/C++ code

## Zig-Specific Considerations

1. **Manual memory management** - Must remember `defer secret.deinit()`
2. **Allocator passing** - Need to pass allocators explicitly
3. **Error handling** - Must handle `!` errors (but this is good!)
4. **More verbose** - More ceremony than high-level languages

## Examples

See `examples/basic.zig` for a comprehensive example showing:
- Creating sensitive strings
- Formatting and printing
- JSON serialization
- Memory management

## License

MIT License - See LICENSE.md for details

## Contributing

Contributions are welcome! Please see the main repository for guidelines.

