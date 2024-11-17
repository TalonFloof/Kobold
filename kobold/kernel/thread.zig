const std = @import("std");
const hal = @import("root").hal;
const Spinlock = @import("root").Spinlock;
const team = @import("team.zig");
const RedBlackTree = @import("perlib").RedBlackTree;
const physmem = @import("physmem.zig");
const scheduler = @import("scheduler.zig");

pub const ThreadState = enum {
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
    priority: usize = 16,
    kstack: []u8,
    gpContext: hal.arch.Context = .{},
    fContext: hal.arch.FloatContext = .{},
};

pub const ThreadList = std.DoublyLinkedList(*Thread);

const ThreadTreeType = RedBlackTree(*Thread, struct {
    fn compare(a: *Thread, b: *Thread) std.math.Order {
        return std.math.order(a.threadID, b.threadID);
    }
}.compare);

pub var threads: ThreadTreeType = ThreadTreeType{};
var threadLock: Spinlock = .unaquired;
pub var nextThreadID: i64 = 1;

pub fn NewThread(
    t: *team.Team,
    name: []const u8,
    ip: usize,
    sp: ?usize,
    prior: usize,
) *Thread { // If SP is null then this is a kernel thread
    const old = hal.arch.intControl(false);
    threadLock.acquire();
    var thread = @as(*Thread, @ptrCast(@alignCast(physmem.Allocate(@sizeOf(Thread), @alignOf(Thread)).?)));
    @memset(@as([*]u8, @ptrFromInt(@intFromPtr(&thread.name)))[0..32], 0);
    @memcpy(@as([*]u8, @ptrFromInt(@intFromPtr(&thread.name))), name);
    thread.queueNode.data = thread;
    thread.semaphoreNode.data = thread;
    thread.teamListNode.data = thread;
    thread.team = t;
    thread.threadID = nextThreadID;
    nextThreadID += 1;
    thread.state = .Runnable;
    thread.priority = prior;
    const stack = @as([*]u8, @ptrFromInt(@intFromPtr(physmem.Allocate(8192, 4096).?)))[0..8192];
    thread.kstack = stack;
    if (sp == null) {
        thread.gpContext.SetMode(true);
        thread.gpContext.SetReg(129, @intFromPtr(stack.ptr) + stack.len);
    } else {
        thread.gpContext.SetMode(false);
        thread.gpContext.SetReg(129, sp.?);
    }
    thread.gpContext.SetReg(128, ip);
    t.threads.append(&thread.teamListNode);
    scheduler.readyQueues[thread.priority].lock.acquire();
    scheduler.readyQueues[thread.priority].queue.prepend(&thread.queueNode);
    scheduler.readyQueues[thread.priority].lock.release();
    threadLock.release();
    _ = hal.arch.intControl(old);
    return thread;
}

pub fn Init() void {
    const kteam = team.GetTeamByID(1).?;
    var i: i32 = 0;
    var buf: [32]u8 = [_]u8{0} ** 32;
    while (i < hal.hiList.?.len) : (i += 1) {
        const name = std.fmt.bufPrint(buf[0..32], "Idle Thread #{}", .{i + 1}) catch {
            @panic("Unable to parse string!");
        };
        _ = NewThread(kteam, name, @intFromPtr(&IdleThread), null, 0);
    }
}

fn IdleThread() callconv(.C) void {
    while (true) {
        hal.arch.waitForInt();
    }
}
