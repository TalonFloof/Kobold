const std = @import("std");

pub const KernelCall = enum {
    Log,
    Panic,
    SpawnKThread,
    MemAlloc,
    MemFree,
    IRQEnableDisable,
    IRQAllocate,
    IRQFree,
    FindPersonality,
    GetDeviceTree, // ACPI-based systems will return the RSDP when you use this, otherwise return a parsed device tree
    IsACPIBased,
    RegisterSyscall,
};

pub const PersonalityHeader = struct {
    name: []const u8,

    prev: ?*PersonalityHeader = null,
    next: ?*PersonalityHeader = null,

    kcall: fn (KernelCall, anytype) ?anyopaque = null,
    customInterface: ?*void = null,
    dependencies: [][]const u8,
};
