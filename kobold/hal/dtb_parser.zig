const std = @import("std");
const dtb = @import("dtb");

pub fn parse_dtb(v: *anyopaque) !void {
    var tree: dtb.Traverser = undefined;
    try tree.init(@as([*]const u8, @ptrCast(v))[0..try dtb.totalSize(v)]);

    var state: enum { Outside, InsideMemory } = .Outside; // Since we don't have a memory allocator yet, we'll have to linearly scan through it and store states as we progress through different nodes.

    while (true) {
        switch (try tree.event()) {
            .BeginNode => |child_name| {
                switch (state) {
                    .Outside => {
                        if (std.mem.startsWith(u8, child_name, "memory@")) {
                            state = .InsideMemory;
                        }
                    },
                    else => unreachable,
                }
            },
            .EndNode => {
                switch (state) {
                    .InsideMemory => {
                        state = .Outside;
                    },
                    else => {},
                }
            },
            .Prop => |prop| {
                _ = prop;
            },
            .End => break,
        }
    }
}
