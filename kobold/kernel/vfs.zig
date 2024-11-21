const std = @import("std");

pub const VNode = extern struct {
    name: [256]u8 = [_]u8{0} ** 256.

    unreferenced: ?*fn (*VNode) callconv(.C) c_long = null,
    open: ?*fn(*VNode) callconv(.C) c_long = null,
    close: ?*fn(*VNode) callconv(.C) c_long = null,
    readDir: ?*fn(*VNode, u32, *DirEntry) callconv(.C) c_long = null,
    findDir: ?*fn(*VNode, [*c]const u8, *?*VNode) callconv(.C) c_long = null,
    truncate: ?*fn(*VNode, usize) callconv(.C) c_long = null,
    create: ?*fn(*VNode, [*c]const u8, usize) callconv(.C) c_long = null,
    unlink: ?*fn(*VNode, [*c]const u8) callconv(.C) c_long = null,
    rename: ?*fn(*VNode, [*c]const u8, *VNode, [*c]const u8) callconv(.C) c_long = null,
    ioctl: ?*fn(*VNode, c_ulong, ?*anyopaque) callconv(.C) c_long = null,

    read: ?*fn(*VNode, usize, *anyopaque, usize) callconv(.C) c_long = null,
    write: ?*fn(*VNode, usize, *anyopaque, usize) callconv(.C) c_long = null,
};