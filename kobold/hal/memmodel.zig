const std = @import("std");
const hal = @import("hal.zig");
const builtin = @import("builtin");
const physmem = @import("root").physmem;
const pfn = @import("root").pfn;

pub const PageDirectory = [*]usize;

pub const LayoutType = enum {
    Flat,
    Paging2Layer, // Only usable if @sizeOf(usize) == 4
    Paging3Layer,
    Paging4Layer,
    Paging5Layer,

    pub fn supportsPaging(self: LayoutType) bool {
        return self == .Paging2Layer or self == .Paging3Layer or self == .Paging4Layer or self == .Paging5Layer;
    }

    pub fn layerCount(self: LayoutType) comptime_int {
        return switch (self) {
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
        highLeaf: u1, // Leaf pages that are not at the lowest level (4 KiB) must set this to 1, for compatibility with x86
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
        highLeaf: u1, // Leaf pages that are not at the lowest level (4 KiB) must set this to 1, for compatibility with x86
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

pub fn MapPage(root: PageDirectory, vaddr: usize, frame: HALPageFrame) usize {
    var i: usize = 0;
    var entries: [*]usize = root;
    while (i < hal.arch.memModel.layout.layerCount()) : (i += 1) {
        const index: u64 = (vaddr >> (39 - @as(u6, @intCast(i * 9)))) & 0x1ff;
        var entry = hal.arch.memModel.nativeToHal.?(entries[index], i + 1 < hal.arch.memModel.layout.layerCount());
        if (i + 1 < hal.arch.memModel.layout.layerCount()) {
            entries[index] = hal.arch.memModel.halToNative.?(frame);
            if (hal.arch.memModel.invalPage) |inval| {
                inval(vaddr);
            }
            if (frame.valid == 0 and entry.valid == 1) {
                if (pfn.DereferencePage(@intFromPtr(entries))) {
                    physmem.Free(@intFromPtr(entries), 4096);
                }
            } else if (frame.valid == 1 and entry.valid == 0) {
                pfn.ReferencePage(@intFromPtr(entries), 1, .noChange);
            }
            return @intFromPtr(&entries[index]);
        } else {
            if (entry.valid != 1) {
                // Allocate a new Page Table
                const page = physmem.Allocate(0x1000, 0x1000).?;
                pfn.ReferencePage(@intFromPtr(page), 0, .pageTable);
                pfn.SetPagePTE(@intFromPtr(page), @intFromPtr(&entries[index]) & 0x7fff_ffff_ffff);
                entry.valid = 1;
                entry.read = 0; // no rwx = branch page
                entry.write = 0;
                entry.execute = 0;
                entry.user = frame.user;
                entry.noCache = 0;
                entry.writeComb = 0;
                entry.writeThru = 0;
                entry.reserved = 0;
                entry.phys = @truncate((page & 0x7fff_ffff_f000) >> 12);
                entries[index] = hal.arch.memModel.halToNative.?(entry);
                pfn.ReferencePage(@intFromPtr(entries), 1, .noChange);
                entries = @as([*]usize, @ptrFromInt(@intFromPtr(page)));
            } else {
                entries = @as([*]usize, @ptrFromInt((@as(usize, @intCast(entry.phys)) << 12) + 0xffff800000000000));
            }
        }
    }
}
