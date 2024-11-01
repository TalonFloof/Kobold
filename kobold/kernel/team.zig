const std = @import("std");
const thread = @import("thread.zig");
const Spinlock = @import("root").Spinlock;

pub const Team = struct {
    teamID: i64,
    mainThread: *allowzero thread.Thread = @ptrFromInt(0),
    parent: ?*Team = null,
    children: ?*Team = null,
    siblingNext: ?*Team = null,
    aspaceLock: Spinlock = .unaquired,
    addressSpace: Memory.Paging.PageDirectory,
};