const std = @import("std");
const hal = @import("root").hal;
const builtin = @import("builtin");

// TODO: Finish This

pub const LayoutType = enum {
    Flat,
    Paging2Layer, // Only usable if @sizeOf(usize) == 4
    Paging3Layer,
    Paging4Layer,
    Paging5Layer,

    pub fn supportsPaging(self: LayoutType) bool {
        return self == .Paging2Layer or self == .Paging3Layer or self == .Paging4Layer or self == .Paging5Layer;
    }

    pub fn layerCount(self: LayoutType) int {
        return switch(self) {
            .Paging2Layer => 2,
            .Paging3Layer => 3,
            .Paging4Layer => 4,
            .Paging5Layer => 5,
            else => 0,
        };
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
        writeComb: u1, // noCache must be 1 and writeThru must be 0 if writeComb is 1, does nothing if not supported
        highLeaf: u1, // Leaf pages that are not at the lowest level (4 KiB) must set this to 1,
                      // for compatibility with x86, non-x86 archs will not have this set during native2hal conversion
                      // unless explicitly used on the native frame
        unused: u3,
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
        writeComb: u1, // noCache must be 1 and writeThru must be 0 if writeComb is 1, does nothing if not supported
        highLeaf: u1, // Leaf pages that are not at the lowest level (4 KiB) must set this to 1,
                      // for compatibility with x86, non-x86 archs will not have this set during native2hal conversion
                      // unless explicitly used on the native frame
        unused: u3,
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
    nativeToHal: ?fn (usize, bool) HALPageFrame = null,
    halToNative: ?fn (HALPageFrame) usize = null,
    changeTable: ?fn (usize) void = null,
    invalPage: ?fn (usize) void = null,
};
