const std = @import("std");
const hal = @import("root").hal;
const Spinlock = @import("spinlock.zig").Spinlock;

pub const PhysicalRange = struct {
    start: usize = 0,
    end: usize = 0,
};

pub const FreeHeader = struct {
    start: usize = 0,
    end: usize = 0,
    prev: ?*FreeHeader = null,
    next: ?*FreeHeader = null,
};

pub const physmem_log = std.log.scoped(.FreeListAllocator);

const FreeCacheList = std.DoublyLinkedList(std.bit_set.StaticBitSet(4096 / @sizeOf(FreeHeader)));

pub const FreeCacheHeader = FreeCacheList.Node;

var lock: Spinlock = .unaquired;

pub const FreeCache = struct {
    full: FreeCacheList = .{},
    partial: FreeCacheList = .{},
    free: FreeCacheList = .{},

    pub fn GetNewEntry(self: *FreeCache) *FreeHeader {
        if (self.full.first == null and self.partial.first == null and self.free.first == null) {
            const header: *FreeCacheHeader = @ptrFromInt(@intFromPtr(&initialCachePage));
            header.data.setRangeValue(.{ .start = 0, .end = 128 }, true);
            header.data.unset(0);
            self.free.prepend(header);
        }
        if (self.partial.first) |partialHead| {
            if (self.free.first == null and partialHead.next == null and partialHead.data.count() <= 2) {
                // Preform Best-Case Allocation
                const page = allocate(0x1000, 0x1000);
                if (page) |p| {
                    const header = @as(*FreeCacheHeader, @alignCast(@ptrCast(p)));
                    header.data.setRangeValue(.{ .start = 0, .end = 128 }, true);
                    header.data.unset(0);
                    self.free.prepend(header);
                    physmem_log.debug("Best-Case Cache Allocation Preformed\n", .{});
                } else {
                    @panic("Best-Case Cache Allocation Failed!");
                }
            }
            if (partialHead.data.findFirstSet()) |index| {
                partialHead.data.unset(index); // Set bit as used
                if (partialHead.data.findFirstSet() == null) {
                    // List is now Full
                    self.partial.remove(partialHead);
                    self.full.prepend(partialHead);
                }
                return @ptrFromInt(@intFromPtr(partialHead) + (index * 32));
            }
            unreachable;
        } else if (self.free.first) |freeHead| {
            if (freeHead.data.findFirstSet()) |index| {
                freeHead.data.unset(index);
                self.free.remove(freeHead);
                self.partial.prepend(freeHead);
                return @ptrFromInt(@intFromPtr(freeHead) + (index * 32));
            }
            unreachable;
        } else {
            physmem_log.warn("Worst-case cache allocation was preformed!", .{});
            const page = allocate(0x1000, 0x1000);
            if (page) |p| {
                const header = @as(*FreeCacheHeader, @alignCast(@ptrCast(p)));
                header.data.setRangeValue(.{ .start = 0, .end = 128 }, true);
                header.data.unset(0);
                if (header.data.findFirstSet()) |index| {
                    header.data.unset(index);
                    self.partial.prepend(header);
                    return @ptrFromInt(@intFromPtr(header) + (index * 32));
                }
                unreachable;
            }
            @panic("Out of Memory");
        }
    }

    pub fn RemoveEntry(self: *FreeCache, entry: *FreeHeader) void {
        if (entry.prev) |prev| {
            prev.next = entry.next;
        } else {
            firstFree = entry.next;
        }
        if (entry.next) |next| {
            next.prev = entry.prev;
        }
        const header: *FreeCacheHeader = @ptrFromInt(hal.AlignDown(usize, @intFromPtr(entry), 4096));
        if (header.data.count() == 0) { // Full -> Partial
            self.full.remove(header);
            self.partial.prepend(header);
        } else if (header.data.count() >= 126) { // Partial -> Free
            self.partial.remove(header);
            self.free.prepend(header);
        } // Partial - Partial
        const entryNumber = (@intFromPtr(entry) - @intFromPtr(header)) / 32;
        header.data.set(entryNumber);
    }
};

var initialCachePage: [4096]u8 align(4096) = [_]u8{0} ** 4096;
var freeCache: FreeCache = .{};

var firstFree: ?*FreeHeader = null;

pub var freeMem: usize = 0;
pub var usedMem: usize = 0;
pub var reservedMem: usize = 0;

fn allocate(size: usize, align_: usize) ?*anyopaque {
    const newSize = size + align_;
    freeMem -= size;
    usedMem += size;

    var cursor = firstFree;
    while (cursor) |node| {
        const region_start = node.start;
        const region_size = node.end - node.start;
        const next = node.next;
        if (region_size > newSize) {
            if (align_ > 0) {
                const newAddr = hal.AlignUp(usize, region_start, align_);
                node.start += size + (newAddr - region_start);
                if (newAddr != region_start) {
                    // insert new entry
                    var entry = freeCache.GetNewEntry();
                    entry.next = node;
                    entry.prev = node.prev;
                    node.prev = entry;
                    entry.start = region_start;
                    entry.end = newAddr;
                    if (entry.prev == null)
                        firstFree = entry;
                }
                return @ptrFromInt(newAddr);
            } else {
                node.start += size;
                return @ptrFromInt(region_start);
            }
        } else if (region_size == newSize) {
            if (align_ > 0) {
                const newAddr = hal.AlignUp(usize, region_start, align_);
                if (newAddr != region_start) {
                    node.end = newAddr;
                }
                return @ptrFromInt(newAddr);
            } else {
                freeCache.RemoveEntry(node);
                return @ptrFromInt(region_start);
            }
        }
        cursor = next;
    }
    freeMem += size;
    usedMem -= size;
    return null;
}

pub fn Allocate(size: usize, align_: usize) ?*anyopaque {
    lock.acquire();
    const s = hal.AlignUp(usize, size, 16);
    const a = allocate(s, align_);
    lock.release();
    return a;
}

pub fn Free(address: usize, s: usize) void {
    lock.acquire();
    const size = hal.AlignUp(usize, s, 16);
    freeMem += size;
    const end = address + size;
    var cursor = firstFree;
    var prev: ?*FreeHeader = null;
    while (cursor) |node| {
        const region_start = node.start;
        const region_end = node.end;
        const next = node.next;
        if (region_start == end) {
            node.start = address;
            if (node.prev) |prv| {
                const prev_region_end = prv.end;
                if (prev_region_end == address) {
                    prv.end = region_end;
                    freeCache.RemoveEntry(node);
                }
            }
            lock.release();
            return;
        } else if (region_end == address) {
            node.end = end;
            if (node.next) |nxt| {
                const next_region_start = nxt.start;
                if (next_region_start == end) {
                    nxt.start = region_start;
                    freeCache.RemoveEntry(node);
                }
            }
            lock.release();
            return;
        } else if (end < region_start) {
            var entry = freeCache.GetNewEntry();
            entry.next = node;
            entry.prev = node.prev;
            node.prev = entry;
            entry.start = address;
            entry.end = end;
            if (prev == null)
                firstFree = entry;
            lock.release();
            return;
        }
        prev = cursor;
        cursor = next;
    }
    var entry = freeCache.GetNewEntry();
    entry.next = null;
    entry.prev = prev;
    entry.start = address;
    entry.end = end;
    if (prev == null) {
        firstFree = entry;
    } else {
        prev.?.next = entry;
    }
    lock.release();
}

pub fn AllocateC(size: usize) callconv(.C) ?*anyopaque {
    return Allocate(size, @alignOf(usize));
}

pub fn FreeC(addr: ?*anyopaque, size: usize) callconv(.C) void {
    Free(@intFromPtr(addr.?), size);
}

pub fn PrintMap(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    _ = iter;
    var cursor = firstFree;
    while (cursor) |node| {
        std.log.debug("0x{x}-0x{x} Free\n", .{ node.start, node.end - 1 });
        cursor = node.next;
    }
    std.log.debug(" {} KiB Used\n {} KiB System Reserved\n {} KiB Free\n {} KiB Total\n", .{ usedMem / 1024, reservedMem / 1024, freeMem / 1024, (usedMem + reservedMem + freeMem) / 1024 });
}

pub fn DebugInit() void {
    hal.debug.NewDebugCommand("freeMap", "Prints all avaiable ranges of memory that can be used for allocations", &PrintMap);
}
