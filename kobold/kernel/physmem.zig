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

var internalFreeListBuf: [2]FreeHeader = [_]FreeHeader{.{}} ** 2;

var firstFree: ?*FreeHeader = null;

fn getNewEntry() *FreeHeader {
    for (0..internalFreeListBuf.len) |i| {
        if (internalFreeListBuf[i].end == 0) {
            return &internalFreeListBuf[i];
        }
    }
    return @ptrCast(Allocate(@sizeOf(FreeHeader), 0).?);
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
            internalFreeListBuf[i].size = 0;
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
    while (cursor) |node| {
        const region_start = node.start;
        const region_end = node.end;
        const next = node.next;
        if (region_start == end) {
            node.start = address;
            if (node.prev) |prev| {
                const prev_region_end = prev.end;
                if (prev_region_end == address) {
                    prev.end = region_end;
                    removeEntry(node);
                }
            }
            return;
        }
        cursor = next;
    }
}
