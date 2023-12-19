const std = @import("std");

pub fn build(b: *std.Build) !void {
    const ndk_version = b.option(usize, "ndk_version", "ndk version") orelse 34;
    const artifact_raw = b.option(usize, "artifact", "artifact") orelse
        @panic("unexpected error, artifact is null");
    const artifact: *std.Build.Step.Compile = @ptrFromInt(artifact_raw);
    const t = artifact.target_info.target;
    const include_dir = sdkPath("/include");
    const root_dir = std.fs.path.dirname(@src().file) orelse ".";
    const lib_dir = b.fmt("{s}/lib/{s}-linux-android/{d}", .{
        root_dir,
        @tagName(t.cpu.arch),
        ndk_version,
    });
    const sys_include_dir = b.fmt("{s}/include/{s}-linux-android", .{
        root_dir,
        @tagName(t.cpu.arch),
    });
    artifact.linkLibC();
    artifact.defineCMacro("ANDROID", null);
    artifact.addLibraryPath(.{ .cwd_relative = lib_dir });
    artifact.setLibCFile(try createLibCFile(b, .{
        .crt_dir = lib_dir,
        .sdk_version = ndk_version,
        .include_dir = include_dir,
        .sys_include_dir = sys_include_dir,
    }));
    artifact.libc_file.?.addStepDependencies(&artifact.step);
}

fn sdkPath(comptime suffix: []const u8) []const u8 {
    if (suffix[0] != '/') @compileError("suffix must be an absolute path");
    return comptime blk: {
        const root_dir = std.fs.path.dirname(@src().file) orelse ".";
        break :blk root_dir ++ suffix;
    };
}

const CreateLibCFileOptions = struct {
    sdk_version: usize,
    include_dir: []const u8,
    sys_include_dir: []const u8,
    crt_dir: []const u8,
};

fn createLibCFile(b: *std.Build, options: CreateLibCFileOptions) !std.build.FileSource {
    const fname = b.fmt("android-{d}.conf", .{options.sdk_version});

    var contents = std.ArrayList(u8).init(b.allocator);
    errdefer contents.deinit();

    var writer = contents.writer();

    // The directory that contains `stdlib.h`.
    // On POSIX-like systems, include directories be found with: `cc -E -Wp,-v -xc /dev/null
    try writer.print("include_dir={s}\n", .{options.include_dir});

    // The system-specific include directory. May be the same as `include_dir`.
    // On Windows it's the directory that includes `vcruntime.h`.
    // On POSIX it's the directory that includes `sys/errno.h`.
    try writer.print("sys_include_dir={s}\n", .{options.sys_include_dir});

    try writer.print("crt_dir={s}\n", .{options.crt_dir});
    try writer.writeAll("msvc_lib_dir=\n");
    try writer.writeAll("kernel32_lib_dir=\n");
    try writer.writeAll("gcc_dir=\n");

    const step = b.addWriteFile(fname, contents.items);
    return step.files.items[0].getPath();
}
