const std = @import("std");
const hal = @import("root").hal;
const sbi = @import("sbi.zig");
const trap = @import("trap.zig");

export var initStack = [_]u8{0} ** 8192;

var useLegacyDebugCon: bool = true;

const arch_log = std.log.scoped(.HAL_RISCV64);

var zeroHart: hal.HartInfo = .{};

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

fn ArchInit(stackTop: usize, dtb: *allowzero anyopaque) void {
    _ = stackTop;
    asm volatile ("csrw sscratch, %[arg1]"
        :
        : [arg1] "r" (&zeroHart),
    );
    useLegacyDebugCon = !sbi.dbcn.available();
    if (useLegacyDebugCon) {
        arch_log.warn("Using Legacy SBI Console!", .{});
    }
    hal.dtb_parser.parse_dtb(dtb) catch @panic("DTB Parse Failed!");
    trap.stub();
}

fn ArchWriteString(_: @TypeOf(.{}), string: []const u8) error{}!usize {
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

fn ArchGetHart() *hal.HartInfo {
    return @as(*hal.HartInfo, @ptrFromInt(asm volatile ("csrr %[ret], sscratch"
        : [ret] "=r" (-> u64),
    )));
}

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
    .getHart = ArchGetHart,
};
