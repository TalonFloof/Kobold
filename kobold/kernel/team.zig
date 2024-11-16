const std = @import("std");
const thread = @import("thread.zig");
const Spinlock = @import("root").Spinlock;
const hal = @import("root").hal;
const RedBlackTree = @import("perlib").RedBlackTree;

pub const Team = struct {
    teamID: i64,
    name: [32]u8 = [_]u8{0} ** 32,
    threads: thread.ThreadList, // Head thread is always main thread
    parent: ?*Team = null,
    aspaceLock: Spinlock = .unaquired,
    addressSpace: hal.memmodel.PageDirectory,
};

const TeamTreeType = RedBlackTree(*Team, struct {
    fn compare(a: *Team, b: *Team) std.math.Order {
        return std.math.order(a.teamID, b.teamID);
    }
}.compare);
