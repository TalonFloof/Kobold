const std = @import("std");

pub const Message = struct {
    sourceTID: usize = 0,
    memBase: usize = 0,
    memSize: usize = 0,
    bufSize: usize = 0,
    buf: *anyopaque = undefined,
};