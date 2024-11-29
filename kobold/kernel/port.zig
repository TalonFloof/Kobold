const std = @import("std");
const team = @import("team.zig");

pub const Message = struct {
    sourceTID: usize = 0,
    memBase: usize = 0,
    memSize: usize = 0,
    bufSize: usize = 0,
    buf: *anyopaque = undefined,
};

pub const Port = struct {
    id: u64,
    creatorTeam: *team.Team = undefined,
    badge: u64 = 0, // 0 = Null Badge
    name: [32]u8 = [_]u8{0} ** 32,
};
