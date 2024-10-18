const std = @import("std");

pub const Thread = struct {
    prevQueue: ?*Thread = null,
    nextQueue: ?*Thread = null,
};
