## Android NDK packaged for zig
### Example build script
```zig
const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const exe = b.addExecutable(.{
        .name = "playground",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const ndk_dep = b.dependency("ndk", .{
        .ndk_version = @as(usize, 34),
        .artifact = @intFromPtr(exe),
    });
    exe.addModule("ndk", ndk_dep.module("ndk"));
    exe.linkSystemLibrary("log");
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
```
### Example module usage
```zig
const std = @import("std");
const ndk = @import("ndk");
const log = std.log.scoped(.NDK_TEST);

pub fn main() !void {
    log.info("hello world", .{});
}

pub const std_options = struct {
    pub const log_level = .info;
    pub const logFn = ndk.logFn;
};
```
