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

pub export fn HALInitialize(stackTop: usize, dtb: *allowzero anyopaque) callconv(.C) noreturn {
    arch.ArchInit(stackTop, dtb);
    root.KoboldInit();
    while (true) {}
}

pub fn stub() void {}
