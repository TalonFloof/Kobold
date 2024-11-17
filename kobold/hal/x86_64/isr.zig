const std = @import("std");
const hal = @import("../hal.zig");
const apic = @import("apic.zig");
const scheduler = @import("root").scheduler;

pub fn stub() void {}

pub export fn ExceptionHandler(entry: u8, con: *hal.arch.Context) callconv(.C) void {
    // TODO: Write Exception Handler
    std.log.err("Unexpected Exception 0x{x}", .{entry});
    con.Dump();
    hal.HALOops("Unexpected Exception!");
}

pub export fn IRQHandler(entry: u8, con: *hal.arch.Context) callconv(.C) *hal.arch.Context {
    // TODO: Write IRQ Handler
    apic.write(0xb0, 0);
    if (entry - 0x20 == 0x0) {
        const queue = &(hal.arch.getHart()).alarmQueue;
        queue.lock.acquire();
        queue.schedule();
        queue.lock.release();
        if (hal.arch.getHart().schedulePending) {
            hal.arch.getHart().schedulePending = false;
            scheduler.Schedule(con);
        }
    }
    return con;
}
