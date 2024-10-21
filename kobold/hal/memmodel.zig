const std = @import("std");
const hal = @import("root").hal;
const builtin = @import("builtin");

// TODO: Finish This

pub const LayoutType = enum {
    Flat,
    Paging2Layer,
    Paging3Layer,
    Paging4Layer,
    Paging5Layer,

    pub fn supportsPaging(self: LayoutType) bool {
        return self == .Paging2Layer or self == .Paging3Layer or self == .Paging4Layer or self == .Paging5Layer;
    }
};

pub const HALPageFrame = switch (@sizeOf(usize)) {
    4 => packed struct {
        valid: u1,
        read: u1,
        write: u1,
        execute: u1,
        user: u1,
        noCache: u1,
        writeThru: u1,
        writeComb: u1, // noCache must be 1 and writeThru must be 0 if writeComb is 1
        unused: u4,
        phys: u20,

        comptime {
            if (@sizeOf(@This()) != 4)
                @compileError("HALPageFrame does not match usize!");
        }
    },
    8 => packed struct {
        valid: u1,
        read: u1,
        write: u1,
        execute: u1,
        user: u1,
        noCache: u1,
        writeThru: u1,
        writeComb: u1, // noCache must be 1 and writeThru must be 0 if writeComb is 1
        unused: u4,
        phys: u44,
        reserved: u8,

        comptime {
            if (@sizeOf(@This()) != 8)
                @compileError("HALPageFrame does not match usize!");
        }
    },
    else => @compileError("Unsupported Arch USize"),
};

pub const MemoryModel = struct {
    layout: LayoutType,
    mmFrameToHalFrame: ?fn (usize) HALPageFrame = null,
    halFrameToMmFrame: ?fn (HALPageFrame) usize = null,
};
