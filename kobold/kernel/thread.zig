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
    prevQueue: ?*Thread = null,
    nextQueue: ?*Thread = null,
    prevTeamThread: ?*Thread = null,
    nextTeamThread: ?*Thread = null,
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

pub const Queue = struct {
    lock: Spinlock = .unaquired,
    head: ?*Thread = null,
    tail: ?*Thread = null,

    pub fn Add(self: *Queue, t: *Thread) void {
        t.nextQueue = null;
        t.prevQueue = self.tail;
        if (self.tail != null) { // hehehe tail owo~
            self.tail.?.nextQueue = t;
        }
        self.tail = t;
        if (self.head == null) {
            self.head = t;
        }
    }

    pub fn Remove(self: *Queue, t: *Thread) void {
        if (t.nextQueue) |nxt| {
            nxt.prevQueue = t.prevQueue;
        }
        if (t.prevQueue) |prev| {
            prev.nextQueue = t.nextQueue;
        }
        if (@intFromPtr(self.head) == @intFromPtr(t)) {
            self.head = t.nextQueue;
        }
        if (@intFromPtr(self.tail) == @intFromPtr(t)) {
            self.tail = t.prevQueue;
        }
        t.nextQueue = null;
        t.prevQueue = null;
    }
};
