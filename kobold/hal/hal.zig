const std = @import("std");
const builtin = @import("builtin");
pub const dtb_parser = @import("dtb_parser.zig");
const root = @import("root");

pub const Writer = std.io.Writer(@TypeOf(.{}), error{}, arch.ArchWriteString);
pub const writer = Writer{ .context = .{} };

pub const arch = switch (builtin.cpu.arch) {
    .riscv64 => @import("riscv64/main.zig"),
    else => @panic("Unsupported Arch!"),
};

// #define ALIGN_UP(s, a)      (((s) + ((a) - 1)) & ~((a) - 1))
//#define ALIGN_DOWN(s, a)    ((s) & ~((a) - 1))
//#define ALIGNED(s, a)       (!((s) & ((a) - 1)))

pub inline fn AlignUp(comptime T: type, s: T, a: T) T {
    return (((s) + ((a) - 1)) & ~((a) - 1));
}
pub inline fn AlignDown(comptime T: type, s: T, a: T) T {
    return ((s) & ~((a) - 1));
}
pub inline fn Aligned(comptime T: type, s: T, a: T) T {
    return (!((s) & ((a) - 1)));
}

pub export fn HALInitialize(stackTop: usize, dtb: *allowzero anyopaque) callconv(.C) noreturn {
    arch.ArchInit(stackTop, dtb);
    root.KoboldInit();
    @panic("No Command");
}

pub fn stub() void {}
