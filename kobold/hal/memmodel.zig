const std = @import("std");
const hal = @import("root").hal;
const builtin = @import("builtin");

// TODO: Finish This

pub const LayoutType = enum {
    FlatNoProt,
    FlatPhysProt,
    Paging2Layer,
    Paging3Layer,
    Paging4Layer,
    Paging5Layer,

    pub fn supportsPaging(self: LayoutType) bool {
        return self == .Paging2Layer or self == .Paging3Layer or self == .Paging4Layer or self == .Paging5Layer;
    }
};

pub const HALPageFrame = switch(@sizeOf(usize)) {
    4 => extern struct {
        valid: u1,
        read: u1,
        write: u1,
        execute: u1,
        noCache: u1,
        writeThru: u1,
        writeComb: u1,
        unused: u5,
        phys: u20,

        comptime {
            if(@sizeOf(@This()) != 4)
                @compilerError("HALPageFrame does not match usize!");
        }
    },
    8 => extern struct {
        valid: u1,
        read: u1,
        write: u1,
        execute: u1,
        noCache: u1,
        writeThru: u1,
        writeComb: u1,
        unused: u5,
        phys: u44,

        comptime {
            if(@sizeOf(@This()) != 8)
                @compilerError("HALPageFrame does not match usize!");
        }
    },
    else => @compilerError("Unsupported Arch USize"),
};

pub const MemoryModel = struct {
    layout: LayoutType,
    mmFrameToHalFrame: fn () HALPageFrame,
    halFrameToMmFrame: fn () usize,
};