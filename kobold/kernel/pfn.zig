// TODO: PFN Support
const std = @import("std");
const hal = @import("root").hal;
const physmem = @import("physmem.zig");

var pfn: ?[]PFNEntry = null;
var pfnBaseAddr: usize = 0;

pub const PFNEntryType = enum(u8) {
    gpp = 0, // General Purpose Page
    reserved = 1, // Memory that will never be reclaimed
    pageTable = 2, // Memory Reserved for a branch of a page table
    pageDir = 3, // Memory Reserved for the trunk of a page table
};

pub const PFNEntry = packed struct {
    ref: usize,
    pte: u56,
    pfnType: PFNEntryType,
};

pub fn init(base: u64, entries: usize) void {
    hal.debug.DebugInit();
    pfn = @as([*]PFNEntry, @alignCast(@ptrCast(physmem.Allocate(@sizeOf(PFNEntry) * entries, @alignOf(PFNEntry)).?)))[0..entries];
    pfnBaseAddr = base;
    @memset(@as([*]u8, @ptrCast(pfn.?.ptr))[0 .. @sizeOf(PFNEntry) * entries], 0);
    std.log.info("PFN @ 0x{x} ({} entries, {} KiB)", .{ @intFromPtr(pfn.?.ptr), entries, (entries * @sizeOf(PFNEntry)) / 1024 });
}
