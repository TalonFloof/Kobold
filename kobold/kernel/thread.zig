const std = @import("std");
const hal = @import("root").hal;

pub const Thread = struct {
    prevQueue: ?*Thread = null,
    nextQueue: ?*Thread = null,
    gpContext: hal.arch.Context = .{},
};
