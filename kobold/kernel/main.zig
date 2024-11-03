const std = @import("std");
const builtin = @import("builtin");
pub const hal = @import("hal");
pub const physmem = @import("physmem.zig");
pub const Spinlock = @import("spinlock.zig").Spinlock;
pub const elf = @import("elf.zig");
pub const pfn = @import("pfn.zig");
pub const port = @import("port.zig");

pub const kmain_log = std.log.scoped(.KernelMain);

pub fn doLog(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
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
        try hal.writer.print(level.asText() ++ "\x1b[0m\x1b[1;30m {s}", .{@tagName(scope)});
        try hal.writer.print("\x1b[0m " ++ format ++ "\n", args);
    }
}

pub const std_options: std.Options = .{
    .logFn = doLog,
    .log_level = .debug,
};

pub fn panic(msg: []const u8, stacktrace: ?*std.builtin.StackTrace, wat: ?usize) noreturn {
    _ = wat;
    _ = stacktrace;
    _ = hal.arch.intControl(false);
    kmain_log.err("panic (hart 0x0) {s}", .{msg});
    kmain_log.debug("Stack Backtrace\n", .{});
    const frameStart = @returnAddress();
    var it = std.debug.StackIterator.init(frameStart, null);
    while (it.next()) |frame| {
        if (frame == 0) {
            break;
        }
        kmain_log.debug("  \x1b[1;30m0x{x:0>16}\x1b[0m\n", .{frame});
    }
    while (true) {
        _ = hal.arch.intControl(false);
        hal.arch.waitForInt();
    }
}

pub export fn KoboldInit() void {
    _ = hal.AlignDown(u32, 0, 4096); // Prevents release builds from failing
}
