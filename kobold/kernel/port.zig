const std = @import("std");
const RedBlackTree = @import("rbtree.zig").RedBlackTree;
const physmem = @import("physmem.zig");

pub const PortType = enum(u8) {
    Port,
    KIP,
};

pub const Port = struct {
    portID: i64,
    portType: PortType = .Port,
    name: [32]u8 = [_]u8{0} ** 32,
};

pub const KernelInterfacePort = struct {
    portID: i64,
    portType: PortType = .KIP,
    name: [32]u8 = [_]u8{0} ** 32,
    routine: fn (*KernelInterfacePort, []const u8) void,
};

const PortTree = RedBlackTree(anyopaque, struct {
    pub fn call(a: anyopaque, b: anyopaque) std.math.Order {
        return std.math.order(@as(Port, a).portID, @as(Port, b).portID);
    }
}.call);

const ports: PortTree = .{};
var nextPort: i64 = 1;

pub fn NewKIP(name: []const u8) *KernelInterfacePort {
    const node: *PortTree.Node = physmem.AllocateC(@sizeOf(PortTree.Node)).?;
    const port: *KernelInterfacePort = @ptrCast(&node.key);
    port.portType = .KIP;
    @memcpy(@as([*]u8, @ptrCast(&port.name)), name);
    port.portID = nextPort;
    nextPort += 1;
    return port;
}
