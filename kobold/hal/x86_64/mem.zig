const std = @import("std");
const limine = @import("limine");
const physmem = @import("root").physmem;
const pfn = @import("root").pfn;

export var memMap: limine.MemoryMapRequest = .{};

pub fn init() void {
    var lowestAddress: usize = ~@as(usize, 0);
    var highestAddress: usize = 0;
    for (memMap.response.?.entries()) |entry| {
        if (entry.kind == .usable) {
            const start = entry.base + 0xffff8000_00000000;
            const end = start + (entry.length);
            std.log.info("mem [0x{x:0>16}-0x{x:0>16}] {s}", .{ entry.base + 0xffff8000_00000000, entry.base + (entry.length - 1) + 0xffff8000_00000000, @tagName(entry.kind) });
            if (start < lowestAddress) {
                lowestAddress = start;
            }
            if (highestAddress < end) {
                highestAddress = end;
            }
            physmem.Free(entry.base + 0xffff8000_00000000, entry.length);
        }
    }
    std.log.info("PFN Information Coverage Range 0x{x:0>16}-0x{x:0>16} ({} entries)", .{ lowestAddress, highestAddress, (highestAddress - lowestAddress) / 4096 });
    pfn.init(lowestAddress, (highestAddress - lowestAddress) / 4096);
}
