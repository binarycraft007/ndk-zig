const std = @import("std");
const log = std.log;
const c = @cImport({
    @cDefine("ANDROID", "");
    @cInclude("android/log.h");
});

const Error = std.fs.File.WriteError;

pub fn logFn(
    comptime message_level: log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const context = Context(message_level, scope){};
    std.fmt.format(context.writer(), format ++ &[1]u8{0}, args) catch return;
    return;
}

fn Context(
    comptime message_level: log.Level,
    comptime scope: @TypeOf(.enum_literal),
) type {
    const level = switch (message_level) {
        .info => c.ANDROID_LOG_INFO,
        .err => c.ANDROID_LOG_ERROR,
        .warn => c.ANDROID_LOG_WARN,
        .debug => c.ANDROID_LOG_DEBUG,
    };

    return struct {
        const Self = @This();

        pub const log_level = level;
        pub const log_scope = scope;

        pub fn writer(self: Self) Writer {
            return .{ .context = self };
        }

        pub fn write(self: Self, bytes: []const u8) Error!usize {
            _ = self;
            const writeFn = c.__android_log_write;
            const rc = writeFn(Self.log_level, @tagName(Self.log_scope), @ptrCast(bytes));
            switch (std.os.errno(rc)) {
                .SUCCESS => return @intCast(rc),
                .INTR => unreachable,
                .INVAL => unreachable,
                .FAULT => unreachable,
                .AGAIN => unreachable,
                .BADF => return error.NotOpenForWriting, // can be a race condition.
                .DESTADDRREQ => unreachable, // `connect` was never called.
                .DQUOT => return error.DiskQuota,
                .FBIG => return error.FileTooBig,
                .IO => return error.InputOutput,
                .NOSPC => return error.NoSpaceLeft,
                .PERM => return error.AccessDenied,
                .PIPE => return error.BrokenPipe,
                else => |err| return std.os.unexpectedErrno(err),
            }
        }

        pub const Writer = std.io.Writer(Self, Error, write);
    };
}
