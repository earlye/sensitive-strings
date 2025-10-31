const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create module
    const sensitive_string_module = b.addModule("sensitive_string", .{
        .root_source_file = b.path("src/sensitive_string.zig"),
    });

    // Tests - using addTest with the module
    const lib_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/sensitive_string.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_lib_tests = b.addRunArtifact(lib_tests);
    
    // Show test output
    if (b.args) |args| {
        run_lib_tests.addArgs(args);
    }
    
    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_lib_tests.step);

    // Example executable
    const example_exe = b.addExecutable(.{
        .name = "example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    example_exe.root_module.addImport("sensitive_string", sensitive_string_module);
    
    const install_example = b.addInstallArtifact(example_exe, .{});
    const example_step = b.step("example", "Build and run the example");
    example_step.dependOn(&install_example.step);

    const run_example = b.addRunArtifact(example_exe);
    run_example.step.dependOn(&install_example.step);
    example_step.dependOn(&run_example.step);
}
