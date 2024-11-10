const std = @import("std");
const hal = @import("../hal.zig");
const apic = @import("apic.zig");

pub fn stub() void {}

pub export fn ExceptionHandler(entry: u8, con: *hal.arch.Context) callconv(.C) void {
    // TODO: Write Exception Handler
    std.log.err("Unexpected Exception 0x{x}", .{entry});
    con.Dump();
    hal.HALOops("Unexpected Exception!");
}

pub export fn IRQHandler(entry: u8, con: *hal.arch.Context) callconv(.C) *hal.arch.Context {
    // TODO: Write IRQ Handler
    std.log.warn("IRQ 0x{x}!", .{entry - 0x20});
    apic.write(0xb0, 0);
    return con;
}
