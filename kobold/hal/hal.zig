const std = @import("std");
const builtin = @import("builtin");
pub const dtb_parser = @import("dtb_parser.zig");
const root = @import("root");
pub const archData = (switch (builtin.cpu.arch) {
    .riscv64 => @import("riscv64/main.zig"),
    .x86_64 => @import("x86_64/main.zig"),
    else => @panic("Unsupported Arch!"),
});
pub const arch: ArchInterface = archData.Interface;
pub const HartInfo = @import("hart.zig").HartInfo;
const memmodel = @import("memmodel.zig");

pub const Writer = std.io.Writer(@TypeOf(.{}), error{}, arch.write);
pub const writer = Writer{ .context = .{} };

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
    arch.init(stackTop, dtb);
    if (arch.memModel.layout == .Flat)
        @panic("MMUless setups are not supported!");
    root.KoboldInit();
    @panic("No Command");
}

pub const ArchInterface = struct {
    init: fn (stackTop: usize, dtb: *allowzero anyopaque) void,
    write: fn (_: @TypeOf(.{}), string: []const u8) error{}!usize,
    getHart: fn () *HartInfo,
    intControl: fn (bool) bool,
    waitForInt: fn () void,
    memModel: memmodel.MemoryModel,
    Context: type,
};
