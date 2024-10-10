const std = @import("std");
pub const hal = @import("hal");
pub const physmem = @import("physmem.zig");
pub const Spinlock = @import("Spinlock.zig").Spinlock;

pub fn doLog(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    switch (level) {
        .info => {
            _ = try hal.writer.write("\x1b[36m");
        },
        .warn => {
            _ = try hal.writer.write("\x1b[33m");
        },
        .err => {
            _ = try hal.writer.write("\x1b[31m");
        },
        else => {},
    }
    if (level == .debug) {
        try hal.writer.print(format, args);
    } else {
        try hal.writer.print(level.asText() ++ "\x1b[0m | " ++ format ++ "\n", args);
    }
}

pub const std_options: std.Options = .{
    .logFn = doLog,
};

pub fn panic(msg: []const u8, stacktrace: ?*std.builtin.StackTrace, wat: ?usize) noreturn {
    _ = wat;
    _ = stacktrace;
    std.log.err("panic (hart 0x0) {s}", .{msg});
    while (true) {}
}

pub export fn KoboldInit() void {
    hal.stub();
}
