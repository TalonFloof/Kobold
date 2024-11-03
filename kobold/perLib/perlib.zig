const std = @import("std");

pub const KernelCall = enum {
    Log,
    Panic,
    RegisterRuntime,
    RegisterKIP,
    RegisterPort,
    SpawnKThread,
    SendMessage, // Non-KIP Ports Only
    RecieveMessage, // Non-KIP Ports Only
    MemAlloc,
    MemFree,
    IRQEnableDisable,
    IRQAllocate,
    IRQFree,
    FindPersonality,
    GetDeviceTree, // ACPI-based systems will return the RSDP when you use this, otherwise return a parsed device tree
    IsACPIBased,
};

pub const PersonalityHeader = struct {
    name: []const u8,

    prev: ?*PersonalityHeader = null,
    next: ?*PersonalityHeader = null,

    kcall: fn (KernelCall, anytype) ?anyopaque = null,
    customInterface: ?*void = null,
    dependencies: [][]const u8,
};
