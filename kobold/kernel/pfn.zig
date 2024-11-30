// TODO: PFN Support
const std = @import("std");
const hal = @import("root").hal;
const physmem = @import("physmem.zig");
const Spinlock = @import("spinlock.zig").Spinlock;

pub var pfn: ?[]PFNEntry = null;
pub var pfnBaseAddr: usize = 0;
pub var pfnSpinlock: Spinlock = .unaquired;

pub const PFNEntryType = enum(u8) {
    gpp = 0, // General Purpose Page
    reserved = 1, // Memory that will never be reclaimed
    pageTable = 2, // Memory Reserved for a branch of a page table
    pageDir = 3, // Memory Reserved for the trunk of a page table
    noChange = 255, // Not used on the PFN, but tells ReferencePage to not change the entry type
};

pub const PFNEntry = packed struct {
    ref: usize,
    pte: u56,
    pfnType: PFNEntryType,

    comptime {
        if (@sizeOf(@This()) != 16) {
            @compileError("PFNEntry Size != 16!");
        }
    }
};

pub fn GetEntry(a: usize) ?*PFNEntry {
    const addr = a & 0x7fff_ffff_f000;
    if (pfn.?) |p| {
        if (addr >= pfnBaseAddr and addr < pfnBaseAddr + (p.len * 4096)) {
            return &p[(addr - pfnBaseAddr) >> 12];
        }
    }
    return null;
}

pub fn SetPagePTE(addr: usize, pte: usize) void {
    const old = hal.arch.intControl(false);
    pfnSpinlock.acquire();
    const entry = GetEntry(addr);
    if (entry) |e| {
        e.pte = @truncate(pte);
    }
    pfnSpinlock.release();
    _ = hal.arch.intControl(old);
}

pub fn ReferencePage(addr: usize, ref: usize, tag: PFNEntryType) void {
    const old = hal.arch.intControl(false);
    pfnSpinlock.acquire();
    const entry = GetEntry(addr);
    if (entry) |e| {
        e.ref += ref;
        if (tag != .noChange) {
            e.pfnType = tag;
        }
    }
    pfnSpinlock.release();
    _ = hal.arch.intControl(old);
}

pub fn DerferencePage(addr: usize) bool {
    const old = hal.arch.intControl(false);
    pfnSpinlock.acquire();
    const entry = GetEntry(addr);
    if (entry) |e| {
        if (e.refs == 0) {
            const oldState = e.pfnType;
            e.pfnType = .gpp;
            if (e.pte != 0 and oldState == .pageTable) {
                const pt: usize = (e.pte & (~@as(usize, @intCast(0xFFF)))) + 0xffff8000_00000000;
                @as(*usize, @ptrFromInt(entry)).* = 0;
                pfnSpinlock.release();
                if (DerferencePage(pt)) {
                    physmem.Free(pt, 4096);
                }
                _ = hal.arch.intControl(old);
                return true;
            }
            pfnSpinlock.release();
            _ = hal.arch.intControl(old);
            return true;
        }
    }
    pfnSpinlock.release();
    _ = hal.arch.intControl(old);
    return false;
}

pub fn init(base: u64, entries: usize) void {
    hal.debug.DebugInit();
    physmem.DebugInit();
    pfn = @as([*]PFNEntry, @alignCast(@ptrCast(physmem.Allocate(@sizeOf(PFNEntry) * entries, @alignOf(PFNEntry)).?)))[0..entries];
    pfnBaseAddr = base;
    @memset(@as([*]u8, @ptrCast(pfn.?.ptr))[0 .. @sizeOf(PFNEntry) * entries], 0);
    std.log.info("PFN @ 0x{x} ({} entries, {} KiB)", .{ @intFromPtr(pfn.?.ptr), entries, (entries * @sizeOf(PFNEntry)) / 1024 });
}
