const std = @import("std");
const hal = @import("root").hal;

pub fn stub() void {}

pub export fn ExceptionHandler(entry: u8, con: *hal.arch.Context) callconv(.C) void {
    // TODO: Write Exception Handler
    std.log.err("Unexpected Exception 0x{x}", .{entry});
    con.Dump();
    @panic("Unexpected Exception!");
}

pub export fn IRQHandler(entry: u8, con: *hal.arch.Context) callconv(.C) void {
    _ = entry;
    _ = con;
    // TODO: Write IRQ Handler
}
