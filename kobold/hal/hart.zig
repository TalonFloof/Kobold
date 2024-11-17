const std = @import("std");
const builtin = @import("builtin");
const alarmqueue = @import("alarmqueue.zig");

pub const HartInfo = struct {
    pub const ArchData: type = switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub const TSS = extern struct {
                reserved1: u32 align(1) = 0,
                rsp: [3]u64 align(1) = [_]u64{0} ** 3,
                reserved2: u64 align(1) = 0,
                ist: [7]u64 align(1) = [_]u64{0} ** 7,
                reserved3: u64 align(1) = 0,
                reserved4: u16 align(1) = 0,
                ioMapBase: u16 align(1) = 0,
            };

            tss: TSS = TSS{},
            apicID: u32 = 0,
        },
        .riscv32, .riscv64 => struct {},
        else => |v| @compileError("Unsupported Architecture " ++ v),
    };

    tempReg1: usize = 0,
    tempReg2: usize = 0,
    activeContextStack: usize = 0,
    activeSyscallStack: usize = 0,
    trapStack: usize = 0,
    alarmQueue: alarmqueue.AlarmQueue = .{},
    archData: ArchData = ArchData{},
    activeThread: ?*anyopaque = null,
    schedulePending: bool = false,
    hartID: usize = 0,

    comptime {
        if (@offsetOf(@This(), "tempReg1") != 0)
            @panic("HartInfo.tempReg1 offset invalid!");
        if (@offsetOf(@This(), "tempReg2") != @sizeOf(usize))
            @panic("HartInfo.tempReg2 offset invalid!");
        if (@offsetOf(@This(), "activeContextStack") != @sizeOf(usize) * 2)
            @panic("HartInfo.activeContextStack offset invalid!");
        if (@offsetOf(@This(), "activeSyscallStack") != @sizeOf(usize) * 3)
            @panic("HartInfo.activeSyscallStack offset invalid!");
        if (@offsetOf(@This(), "trapStack") != @sizeOf(usize) * 4)
            @panic("HartInfo.trapStack offset invalid!");
    }
};
