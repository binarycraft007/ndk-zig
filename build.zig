const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const t = target.result;
    const ndk_module = b.addModule("ndk", .{
        .root_source_file = .{ .path = "src/root.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const ndk_version = b.option(usize, "ndk_version", "ndk version") orelse 34;
    const lib_path = b.fmt("lib/{s}-linux-android/{d}", .{
        @tagName(t.cpu.arch),
        ndk_version,
    });
    const sys_include_dir = b.fmt("include/{s}-linux-android", .{
        @tagName(t.cpu.arch),
    });
    ndk_module.addIncludePath(.{ .path = "include" });
    ndk_module.addSystemIncludePath(.{ .path = sys_include_dir });
    ndk_module.addLibraryPath(.{ .path = lib_path });
}
