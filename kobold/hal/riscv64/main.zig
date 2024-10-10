const std = @import("std");
const hal = @import("root").hal;
const sbi = @import("sbi.zig");
const trap = @import("trap.zig");

export var initStack = [_]u8{0} ** 8192;

var useLegacyDebugCon: bool = true;

pub const Writer = std.io.Writer(@TypeOf(.{}), error{}, ArchWriteString);

comptime {
    asm (
        \\.section .text.boot
        \\.globl _start
        \\_start:
        \\la sp, initStack
        \\li t0, 8192
        \\add sp, sp, t0
        \\call HALInitialize
    );
}

pub fn ArchInit(stackTop: usize, dtb: *allowzero anyopaque) void {
    _ = stackTop;
    useLegacyDebugCon = !sbi.dbcn.available();
    if (useLegacyDebugCon) {
        std.log.warn("Using Legacy SBI Console!", .{});
    }
    std.log.debug("Kobold Kernel\n", .{});
    hal.dtb_parser.parse_dtb(dtb) catch @panic("DTB Parse Failed!");
    trap.stub();
}

pub fn ArchWriteString(_: @TypeOf(.{}), string: []const u8) error{}!usize {
    if (!useLegacyDebugCon) {
        var i: isize = 0;
        while (i < string.len) {
            i += sbi.dbcn.writeBytes(string[@bitCast(i)..]) catch return 0;
        }
    } else {
        var i: isize = 0;
        while (i < string.len) {
            _ = sbi.legacy.consolePutChar(string[@bitCast(i)]);
            i += 1;
        }
    }
    return string.len;
}
