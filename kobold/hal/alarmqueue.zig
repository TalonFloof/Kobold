// The alarm queue is a queue containing deferred events that need to be called on in the future.
// This mechanism is used for determining the remaining time of a thread's context
// and allows for timeouts to be possible. Now, due to the nature of the alarm queue
// making the assemption that the timer isn't deadline based,
// it is possible for the timings to be behind or ahead of the scheduled deadline
// though this error tends to be within nanosecond ranges, which is not enough for most software to notice.
const std = @import("std");
const hal = @import("hal.zig");
const Spinlock = @import("perlib").Spinlock;
const physmem = @import("root").physmem;

pub const AlarmQueueNode = struct {
    deadline: u64,
    data: ?*anyopaque = null,
    func: *fn (?*anyopaque) callconv(.C) void,
};

const AlarmQueueList = std.DoublyLinkedList(AlarmQueueNode);
pub const AlarmQueue = struct {
    lock: Spinlock = .unaquired,
    list: AlarmQueueList = .{},
    timerCounter: u64 = 0,
    timerNextInterval: u64 = 0,

    pub fn addAlarm(self: *AlarmQueue, timeout: u64, func: *fn (?*anyopaque) callconv(.C) void, data: ?*anyopaque) void {
        const old = hal.arch.intControl(false);
        self.lock.acquire();
        const node: AlarmQueueList.Node = @ptrCast(@alignCast(physmem.Allocate(@sizeOf(AlarmQueueList.Node), @alignOf(AlarmQueueList.node)).?));
        node.data.deadline = hal.arch.getHart().timerCounter + timeout;
        node.data.data = data;
        node.data.func = func;
        self.schedule();
        self.lock.release();
        _ = hal.arch.intControl(old);
    }

    fn schedule(self: *AlarmQueue) void {
        const elapsedTime = hal.arch.getHart().timerNextInterval - hal.arch.getRemainingTime();
        var closestDeadline: u64 = 0xffff_ffff_ffff_ffff;
        var ind = self.list.first;
        while (ind != null) {
            ind = ind.?.next;
        }
    }
};
