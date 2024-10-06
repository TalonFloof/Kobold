const std = @import("std");
const dtb = @import("dtb");
const physmem = @import("root").physmem;
const hal = @import("root").hal;

var freeMemory: [64]physmem.PhysicalRange = [_]physmem.PhysicalRange{.{ .start = 0, .end = 0 }} ** 64;

extern const __KERNEL_BEGIN__: *allowzero anyopaque;
extern const __KERNEL_END__: *allowzero anyopaque;

fn findFirstFree() isize {
    for (0..64) |i| {
        if (freeMemory[i].end == 0)
            return @bitCast(i);
    }
    return -1;
}

fn reserve(start: usize, end: usize) void {
    for (0..64) |i| {
        if (start == freeMemory[i].start and end == freeMemory[i].end) {
            freeMemory[i].start = 0;
            freeMemory[i].end = 0;
            return;
        } else if (freeMemory[i].start < start and freeMemory[i].end == end) {
            freeMemory[i].end = start;
            return;
        } else if (freeMemory[i].start == start and freeMemory[i].end > end) {
            freeMemory[i].start = end;
            return;
        } else if (freeMemory[i].start < start and freeMemory[i].end > end) {
            const oldEnd = freeMemory[i].end;
            freeMemory[i].end = start;
            freeMemory[@bitCast(findFirstFree())] = .{ .start = end, .end = oldEnd };
            return;
        }
    }
}

pub fn parse_dtb(v: *anyopaque) !void {
    var tree: dtb.Traverser = undefined;
    try tree.init(@as([*]const u8, @ptrCast(v))[0..try dtb.totalSize(v)]);

    var state: enum { Outside, InsideMemory, InsideReservedMemory } = .Outside; // Since we don't have a memory allocator yet, we'll have to linearly scan through it and store states as we progress through different nodes.
    var addrSize: u32 = 0;
    var lenSize: u32 = 0;
    var depth: usize = 1;

    var reg: ?[]const u8 = null;

    // Usable Memory, Other Stuff
    while (true) {
        switch (try tree.event()) {
            .BeginNode => |child_name| {
                depth += 1;
                switch (state) {
                    .Outside => {
                        if (std.mem.startsWith(u8, child_name, "memory")) {
                            state = .InsideMemory;
                        }
                    },
                    else => {},
                }
            },
            .EndNode => {
                depth -= 1;
                switch (state) {
                    .InsideMemory => {
                        const entrySize = ((addrSize + lenSize) * 4);
                        const entries = reg.?.len / entrySize;
                        for (0..entries) |i| {
                            const begin: u64 = readCells(addrSize, reg.?[(i * entrySize)..]);
                            const end: u64 = begin + readCells(lenSize, reg.?[((i * entrySize) + (addrSize * 4))..]);
                            freeMemory[@bitCast(findFirstFree())] = .{ .start = begin, .end = end };
                        }
                        state = .Outside;
                    },
                    else => {},
                }
            },
            .Prop => |prop| {
                switch (state) {
                    .InsideMemory => {
                        if (std.mem.eql(u8, prop.name, "reg")) {
                            reg = prop.value;
                        }
                    },
                    .Outside => {},
                    else => {},
                }
                if (std.mem.eql(u8, prop.name, "#address-cells") and addrSize == 0) {
                    addrSize = readU32(prop.value);
                }
                if (std.mem.eql(u8, prop.name, "#size-cells") and lenSize == 0) {
                    lenSize = readU32(prop.value);
                }
            },
            .End => break,
        }
    }
    // Reserved Memory
    try tree.init(@as([*]const u8, @ptrCast(v))[0..try dtb.totalSize(v)]);
    while (true) {
        switch (try tree.event()) {
            .BeginNode => |child_name| {
                depth += 1;
                switch (state) {
                    .Outside => {
                        if (std.mem.startsWith(u8, child_name, "reserved-memory")) {
                            state = .InsideReservedMemory;
                        }
                    },
                    else => {},
                }
            },
            .EndNode => {
                depth -= 1;
                switch (state) {
                    .InsideReservedMemory => {
                        const entrySize = ((addrSize + lenSize) * 4);
                        const entries = reg.?.len / entrySize;
                        for (0..entries) |i| {
                            const begin: u64 = readCells(addrSize, reg.?[(i * entrySize)..]);
                            const end: u64 = begin + readCells(lenSize, reg.?[((i * entrySize) + (addrSize * 4))..]);
                            reserve(begin, end);
                        }
                        state = .Outside;
                    },
                    else => {},
                }
            },
            .Prop => |prop| {
                switch (state) {
                    .InsideReservedMemory => {
                        if (std.mem.eql(u8, prop.name, "reg")) {
                            reg = prop.value;
                        }
                    },
                    .Outside => {},
                    else => {},
                }
            },
            .End => break,
        }
    }
    reserve(@intFromPtr(&__KERNEL_BEGIN__), @intFromPtr(&__KERNEL_END__));
    reserve(@intFromPtr(v), @intFromPtr(v) + try dtb.totalSize(v));
    for (0..64) |i| {
        if (freeMemory[i].end == 0) continue;
        std.log.info("mem [{x}-{x}] Usable", .{ freeMemory[i].start, freeMemory[i].end - 1 });
    }
}

fn readU32(value: []const u8) u32 {
    return std.mem.bigToNative(u32, @as(*const u32, @ptrCast(@alignCast(value.ptr))).*);
}
fn readU64(value: []const u8) u64 {
    return (@as(u64, readU32(value[0..4])) << 32) | readU32(value[4..8]);
}
fn readCells(cell_count: u32, value: []const u8) u64 {
    if (cell_count == 1) {
        if (value.len < @sizeOf(u32))
            @panic("readCells: cell_count = 1, bad len");
        return readU32(value);
    }
    if (cell_count == 2) {
        if (value.len < @sizeOf(u64))
            @panic("readCells: cell_count = 2, bad len");
        return readU64(value);
    }
    @panic("readCells: cell_count unk");
}
