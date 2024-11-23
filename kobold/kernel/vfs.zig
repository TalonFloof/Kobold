const std = @import("std");

pub const Metadata = extern struct {
    deviceID: u64 = 0,
    ID: u64 = 0,
    mode: u32 = 0,
    nlinks: u32 = 0,
    uid: u32 = 1,
    gid: u32 = 1,
    rdev: u64 = 0, // Device ID (Optional)
    size: u64 = 0,
    atime: i64 = 0,
    reserved1: u64 = 0,
    mtime: i64 = 0,
    reserved2: u64 = 0,
    ctime: i64 = 0,
    reserved3: u64 = 0,
    blksize: u64 = 0,
    blocks: u64 = 0,
};

pub const VNode = extern struct {
    name: [256]u8 = [_]u8{0} ** 256,
    stat: Metadata = Metadata{ .ID = 0 },

    unreferenced: ?*fn (*VNode) callconv(.C) c_long = null,
    open: ?*fn (*VNode) callconv(.C) c_long = null,
    close: ?*fn (*VNode) callconv(.C) c_long = null,
    readDir: ?*fn (*VNode, u32, *DirEntry) callconv(.C) c_long = null,
    findDir: ?*fn (*VNode, [*c]const u8, *?*VNode) callconv(.C) c_long = null,
    truncate: ?*fn (*VNode, usize) callconv(.C) c_long = null,
    create: ?*fn (*VNode, [*c]const u8, usize) callconv(.C) c_long = null,
    unlink: ?*fn (*VNode, [*c]const u8) callconv(.C) c_long = null,
    rename: ?*fn (*VNode, [*c]const u8, *VNode, [*c]const u8) callconv(.C) c_long = null,
    ioctl: ?*fn (*VNode, c_ulong, ?*anyopaque) callconv(.C) c_long = null,

    read: ?*fn (*VNode, usize, *anyopaque, usize) callconv(.C) c_long = null,
    write: ?*fn (*VNode, usize, *anyopaque, usize) callconv(.C) c_long = null,
};
