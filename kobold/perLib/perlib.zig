const std = @import("std");
pub const Spinlock = @import("spinlock.zig").Spinlock;
pub const RedBlackTree = @import("rbtree.zig").RedBlackTree;

pub const KernelCall = enum {
    Log,
    TriggerOops,
    SpawnKThread,
    MemAlloc,
    MemFree,
    IRQEnableDisable,
    IRQAllocate,
    IRQFree,
    FindPersonality,
    GetDeviceTree, // ACPI-based systems will return the RSDP when you use this, otherwise return a parsed device tree
    IsACPIBased,
    Sleep,
    Stall,

    RegisterScheme,
    AccessScheme,
};

pub const PersonalityHeader = struct {
    name: []const u8,

    prev: ?*PersonalityHeader = null,
    next: ?*PersonalityHeader = null,

    kcall: fn (KernelCall, anytype) ?anyopaque = null,
    customInterface: ?*void = null,
    dependencies: [][]const u8,
};

// PersonalityLoad is defined here to allow us to setup some stuff for the convience of the developer implementing the driver in question
export fn PersonalityLoad() void {}
