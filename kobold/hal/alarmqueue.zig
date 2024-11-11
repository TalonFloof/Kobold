// The alarm queue is a queue containing deferred events that need to be called on in the future.
// This mechanism is used for determining the remaining time of a thread's context
// and allows for timeouts to be possible. Now, due to the nature of the alarm queue
// making the assemption that the timer isn't deadline based,
// it is possible for the timings to be behind or ahead of the scheduled deadline
// though this error tends to be within nanosecond ranges, which is not enough for most software to notice.
const std = @import("std");
const hal = @import("hal.zig");
const Spinlock = @import("perlib").Spinlock;

pub const AlarmQueueNode = struct {
    deadline: u64,
    data: ?*anyopaque = null,
    func: *fn(?*anyopaque) callconv(.C) void,
};

const AlarmQueueList = std.DoublyLinkedList(AlarmQueueNode);
pub const AlarmQueue = struct {
    lock: Spinlock = .unaquired,
    ticks: u64 = 0,
    list: AlarmQueueList = .{},

    
};