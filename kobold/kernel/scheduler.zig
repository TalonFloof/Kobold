const std = @import("std");
const thread = @import("thread.zig");
const Spinlock = @import("perlib").Spinlock;
const hal = @import("hal");

pub const Queue = struct {
    lock: Spinlock = .unaquired,
    queue: thread.ThreadList = .{},
};

pub var readyQueues: [64]Queue = [_]Queue{Queue{}} ** 64;

fn GetNextThread() *thread.Thread {
    var i: usize = 63;
    while (true) : (i -= 1) {
        if (readyQueues[i].queue.first != null) {
            readyQueues[i].lock.acquire();
            if (readyQueues[i].queue.first != null) {
                const t = readyQueues[i].queue.popFirst();
                readyQueues[i].lock.release();
                return t.?.data;
            } else {
                readyQueues[i].lock.release();
                continue;
            }
        }
        if (i == 0) {
            hal.HALOops("No Available Threads in any of the Run Queues!");
            unreachable;
        }
    }
}

fn rescheduleAlarm(data: ?*anyopaque) callconv(.C) void {
    _ = data;
    hal.arch.getHart().schedulePending = true;
}

pub fn Schedule(con: ?*hal.arch.Context) noreturn {
    const hart = hal.arch.getHart();
    if (hart.activeThread) |activeT| {
        const activeThread: *thread.Thread = @alignCast(@ptrCast(activeT));
        if (con) |c| {
            activeThread.gpContext = c.*;
            activeThread.fContext.Save();
        }
        if (activeThread.state == .Running) {
            activeThread.state = .Runnable;
            readyQueues[activeThread.priority].lock.acquire();
            readyQueues[activeThread.priority].queue.append(&activeThread.queueNode);
            readyQueues[activeThread.priority].lock.release();
        }
    }
    var thr: *thread.Thread = GetNextThread();
    while (true) {
        if (thr.state == .Runnable) {
            thr.state = .Running;
            break;
        } else {
            readyQueues[thr.priority].lock.acquire();
            readyQueues[thr.priority].queue.append(&thr.queueNode);
            readyQueues[thr.priority].lock.release();
        }
        thr = GetNextThread();
    }
    hart.activeThread = @alignCast(@ptrCast(thr));
    hart.activeSyscallStack = @intFromPtr(thr.kstack.ptr) + (thr.kstack.len - 8);
    _ = hart.alarmQueue.addAlarm(10000, &rescheduleAlarm, null);
    thr.fContext.Load();
    thr.gpContext.Enter();
}
