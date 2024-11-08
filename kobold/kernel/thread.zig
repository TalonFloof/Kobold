const std = @import("std");
const hal = @import("root").hal;
const Spinlock = @import("root").Spinlock;
const team = @import("team.zig");

pub const ThreadState = enum {
    Embryo,
    Runnable,
    Running,
    Waiting,
    Debugging,
};

pub const Thread = struct {
    threadID: i64,
    queueNode: ThreadList.Node,
    teamListNode: ThreadList.Node,
    semaphoreNode: ThreadList.Node,
    team: *team.Team,
    name: [32]u8 = [_]u8{0} ** 32,
    state: ThreadState = .Embryo,
    shouldKill: bool = false,
    priority: usize = 31,
    kstack: []u8,
    activeUstack: usize = 0,
    gpContext: hal.arch.Context = .{},
    fContext: hal.Arch.FloatContext = .{},
};

pub const ThreadList = std.DoublyLinkedList(*Thread);
