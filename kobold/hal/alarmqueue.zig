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
    func: *const fn (?*anyopaque) callconv(.C) void,
};

const AlarmQueueList = std.DoublyLinkedList(AlarmQueueNode);
pub const AlarmQueue = struct {
    lock: Spinlock = .unaquired,
    list: AlarmQueueList = .{},
    timerCounter: u64 = 0,
    timerNextInterval: u64 = 0,

    pub fn addAlarm(self: *AlarmQueue, timeout: u64, func: *const fn (?*anyopaque) callconv(.C) void, data: ?*anyopaque) *AlarmQueueList.Node {
        const old = hal.arch.intControl(false);
        self.lock.acquire();
        const node: *AlarmQueueList.Node = @ptrCast(@alignCast(physmem.Allocate(@sizeOf(AlarmQueueList.Node), @alignOf(AlarmQueueList.Node)).?));
        node.data.deadline = self.timerCounter + timeout;
        node.data.data = data;
        node.data.func = func;
        self.list.append(node);
        self.schedule();
        self.lock.release();
        _ = hal.arch.intControl(old);
        return node;
    }

    pub fn removeAlarm(self: *AlarmQueue, aqn: *AlarmQueueList.Node) void {
        const old = hal.arch.intControl(false);
        self.lock.acquire();
        self.list.remove(aqn);
        physmem.Free(@intFromPtr(aqn), @sizeOf(AlarmQueueList.Node));
        self.schedule();
        self.lock.release();
        _ = hal.arch.intControl(old);
    }

    pub fn schedule(self: *AlarmQueue) void {
        const elapsedTime = self.timerNextInterval - hal.arch.getRemainingTime.?();
        self.timerCounter += elapsedTime;
        var closestDeadline: u64 = 0xffff_ffff_ffff_ffff;
        var ind = self.list.first;
        while (ind) |i| {
            if (self.timerCounter >= i.data.deadline) {
                const next = i.next;
                i.data.func(i.data.data);
                self.list.remove(i);
                ind = next;
                physmem.Free(@intFromPtr(i), @sizeOf(AlarmQueueList.Node));
                continue;
            } else if (i.data.deadline < closestDeadline) {
                closestDeadline = i.data.deadline;
                ind = i.next;
            } else {
                ind = i.next;
            }
        }
        if (closestDeadline == 0xffff_ffff_ffff_ffff) {
            self.timerNextInterval = 0;
            return;
        } else {
            self.timerNextInterval = closestDeadline - self.timerCounter;
            hal.arch.setTimerDeadline.?(self.timerNextInterval);
            return;
        }
    }
};
