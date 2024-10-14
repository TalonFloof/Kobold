const std = @import("std");
const builtin = @import("builtin");

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
        },
        else => |v| @compileError("Unsupported Architecture " ++ v),
    };

    tempReg1: usize = 0,
    tempReg2: usize = 0,
    activeContextStack: usize = 0,
    activeSyscallStack: usize = 0,
    trapStack: usize = 0,
    archData: ArchData = ArchData{},
};
