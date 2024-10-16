const std = @import("std");
const limine = @import("limine");

export var memMap: limine.MemoryMapRequest = .{};

pub fn init() void {
    for (memMap.response.?.entries()) |entry| {
        if (entry.kind == .usable) {
            std.log.info("mem [0x{x:0>16}-0x{x:0>16}] {s}", .{ entry.base + 0xffff8000_00000000, entry.base + (entry.length - 1) + 0xffff8000_00000000, @tagName(entry.kind) });
        }
    }
}
