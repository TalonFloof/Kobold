const std = @import("std");

pub const VNode = extern struct {
    name: [256]u8 = [_]u8{0} ** 256.

    unreferenced: ?*fn (*VNode) callconv(.C) c_int = null,
    open: ?*fn(*VNode) callconv(.C) c_int = null,
    close: ?*fn(*VNode) callconv(.C) c_int = null,
    readDir: ?*fn(*VNode, u32, *DirEntry) callconv(.C) c_int = null,
    findDir: ?*fn(*VNode, [*c]const u8, *?*VNode) callconv(.C) c_int = null,
    truncate: ?*fn(*VNode, usize) callconv(.C) c_int = null,
    create: ?*fn(*VNode, [*c]const u8, usize) callconv(.C) c_int = null,
    unlink: ?*fn(*VNode, [*c]const u8) callconv(.C) c_int = null,
    rename: ?*fn(*VNode, [*c]const u8, *VNode, [*c]const u8) callconv(.C) c_int = null,
    ioctl: 
};