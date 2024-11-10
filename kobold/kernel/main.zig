const std = @import("std");
const builtin = @import("builtin");
pub const hal = @import("hal");
pub const physmem = @import("physmem.zig");
pub const Spinlock = @import("perlib").Spinlock;
pub const elf = @import("elf.zig");
pub const pfn = @import("pfn.zig");

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

pub fn panic(msg: []const u8, stacktrace: ?*std.builtin.StackTrace, retAddr: ?usize) noreturn {
    _ = stacktrace;
    _ = hal.arch.intControl(false);
    kmain_log.err("panic (hart 0x{x}) {s}", .{ hal.arch.getHart().hartID, msg });
    hal.debug.PrintBacktrace(retAddr orelse @returnAddress());
    hal.debug.EnterDebugger();
    while (true) {
        _ = hal.arch.intControl(false);
        hal.arch.waitForInt();
    }
}

pub export fn KoboldInit() void {
    _ = hal.AlignDown(u32, 0, 4096); // Prevents release builds from failing
}
