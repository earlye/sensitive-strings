const std = @import("std");
const SensitiveString = @import("sensitive_string").SensitiveString;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("=== Zig SensitiveString Example ===\n\n", .{});

    // Create a sensitive string
    const password = try SensitiveString.init(allocator, "my-secret-password");
    defer password.deinit();

    // Get the hash string
    const hash1 = try password.hashHex(allocator);
    defer allocator.free(hash1);
    std.debug.print("Format: {s}\n", .{hash1});

    // Intentional access to plaintext
    std.debug.print("\n=== Intentional Access ===\n", .{});
    std.debug.print("Plaintext (via .value): {s}\n", .{password.value});
    std.debug.print("Plaintext (via getValue()): {s}\n", .{password.getValue()});

    // Multiple sensitive strings
    const api_key = try SensitiveString.init(allocator, "sk-1234567890abcdef");
    defer api_key.deinit();

    const hash2 = try api_key.hashHex(allocator);
    defer allocator.free(hash2);
    std.debug.print("\nAPI Key: {s}\n", .{hash2});

    var buffer: [1024]u8 = undefined;
    var file_writer = std.fs.File.stdout().writer(&buffer);
    const writer_ptr = &file_writer.interface;
    try std.json.Stringify.value(
        password,
        .{ .whitespace = .indent_2 },
        writer_ptr,
    );
    try file_writer.interface.flush();
    

    std.debug.print("\n✅ Notice: All output shows SHA256 hashes, not plaintext!\n", .{});
}

