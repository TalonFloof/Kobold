const std = @import("std");
const thread = @import("thread.zig");

pub const Semaphore = struct {
    semID: i64 = 0, // 0 id semaphores are special anonymous semaphores used in internal kernel structures like ports
    teamID: i64,
    name: [32]u8 = [_]u8{0} ** 32,
    threadCount: usize,
    queuedThreads: thread.ThreadList = .{},
};
