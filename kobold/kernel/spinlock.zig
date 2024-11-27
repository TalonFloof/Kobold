const std = @import("std");

pub const Spinlock = enum(u8) {
    unaquired = 0,
    aquired = 1,

    pub fn acquire(spinlock: *volatile Spinlock) void {
        var cycles: usize = 0;
        while (cycles < 0x10000000) : (cycles += 1) {
            if (@cmpxchgWeak(Spinlock, spinlock, .unaquired, .aquired, .acquire, .monotonic) == null) {
                return;
            }
            std.atomic.spinLoopHint();
        }
        std.log.err("Deadlock @ 0x{x}", .{@intFromPtr(spinlock)});
        @panic("Deadlock");
    }

    pub inline fn release(spinlock: *volatile Spinlock) void {
        @atomicStore(Spinlock, spinlock, .unaquired, .release);
    }
};
