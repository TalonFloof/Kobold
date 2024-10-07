const std = @import("std");
const hal = @import("root").hal;

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

var internalFreeListBuf: [4]FreeHeader = [_]FreeHeader{.{}} ** 4;

var firstFree: ?*FreeHeader = null;

fn getNewEntry() *FreeHeader {
    for (0..internalFreeListBuf.len) |i| {
        if (internalFreeListBuf[i].end == 0) {
            return &internalFreeListBuf[i];
        }
    }
    return @ptrCast(@alignCast(Allocate(@sizeOf(FreeHeader), 0).?));
}

fn removeEntry(ptr: *FreeHeader) void {
    if (ptr.prev) |prev| {
        prev.next = ptr.next;
    } else {
        firstFree = ptr.next;
    }
    if (ptr.next) |next| {
        next.prev = ptr.prev;
    }
    for (0..internalFreeListBuf.len) |i| {
        if (@intFromPtr(ptr) == @intFromPtr(&internalFreeListBuf[i])) {
            internalFreeListBuf[i].end = 0;
            return;
        }
    }
    Free(@intFromPtr(ptr), @sizeOf(FreeHeader));
}

pub fn Allocate(size: usize, align_: usize) ?*anyopaque {
    const newSize = size + align_;

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
                    var entry = getNewEntry();
                    entry.next = node;
                    entry.prev = node.prev;
                    node.prev = entry;
                    entry.start = region_start;
                    entry.end = newAddr;
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
                removeEntry(node);
                return @ptrFromInt(region_start);
            }
        }
        cursor = next;
    }
    return null;
}

pub fn Free(address: usize, size: usize) void {
    const end = address + size;
    var cursor = firstFree;
    var prev: ?*FreeHeader = null;
    while (cursor) |node| {
        const region_start = node.start;
        const region_end = node.end;
        const next = node.next;
        prev = node.prev;
        if (region_start == end) {
            node.start = address;
            if (node.prev) |prv| {
                const prev_region_end = prv.end;
                if (prev_region_end == address) {
                    prv.end = region_end;
                    removeEntry(node);
                }
            }
            return;
        } else if (region_end == address) {
            node.end = end;
            if (node.next) |nxt| {
                const next_region_start = nxt.start;
                if (next_region_start == end) {
                    nxt.start = region_start;
                    removeEntry(node);
                }
            }
            return;
        } else if (end < region_start) {
            var entry = getNewEntry();
            entry.next = node;
            entry.prev = node.prev;
            node.prev = entry;
            entry.start = address;
            entry.end = end;
            if (prev == null)
                firstFree = entry;
            return;
        }
        cursor = next;
    }
    var entry = getNewEntry();
    entry.next = null;
    entry.prev = prev;
    entry.start = address;
    entry.end = end;
    if (prev == null) {
        firstFree = entry;
    } else {
        prev.?.next = entry;
    }
}

pub fn PrintMap() void {
    var cursor = firstFree;
    while (cursor) |node| {
        std.log.info("{x}-{x} Free", .{ node.start, node.end - 1 });
        cursor = node.next;
    }
}
