const std = @import("std");

pub const KernelCall = enum {
    Log,
    Panic,
    RegisterRuntime,
    MemAlloc,
    MemFree,
};

pub const PersonalityHeader = struct {
    name: []const u8,

    prev: ?*PersonalityHeader = null,
    next: ?*PersonalityHeader = null,

    kcall: fn (KernelCall, anytype) void = null,
    customInterface: ?*void = null,
};
