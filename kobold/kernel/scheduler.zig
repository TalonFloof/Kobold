const std = @import("std");
const thread = @import("thread.zig");
const Spinlock = @import("spinlock.zig").Spinlock;

pub const Queue = struct {
    lock: Spinlock = .unaquired,
    queue: thread.ThreadList = .{},
};

pub var readyQueues: [64]Queue = [_]Queue{Queue{}} ** 64;
