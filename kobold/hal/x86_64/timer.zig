const std = @import("std");
const hal = @import("root").hal;
const io = @import("io.zig");
const apic = @import("apic.zig");
const acpi = @import("acpi.zig");

extern fn ExecuteNInstructions(u32) callconv(.C) void;

pub fn rdtsc() u64 {
    var rax: u64 = undefined;
    var rdx: u64 = undefined;
    asm volatile (
        \\rdtsc
        : [rax] "={rax}" (rax),
          [rdx] "={rdx}" (rdx),
    );
    return (rdx << 32) | (rax & 0xFFFFFFFF);
}

var ticksPerSecond: u64 = 0;

pub fn init() void {
    if (ticksPerSecond == 0) {
        if (acpi.HPETAddr != null) {
            const addr: usize = acpi.HPETAddr.?.address;
            const hpetAddr: [*]align(1) volatile u64 = @as([*]align(1) volatile u64, @ptrFromInt(addr));
            const clock = hpetAddr[0] >> 32;

            apic.hpetPeriod = @floatFromInt(clock);
            apic.hpetNSPeriod = apic.hpetPeriod / 1000000.0;
            apic.hpetTicksPer100NS = 100000000.0 / apic.hpetPeriod;
            hpetAddr[2] = 0;
            hpetAddr[30] = 0;
            hpetAddr[2] = 1;

            const hz = 1000000000000000.0 / @as(f64, @floatFromInt(clock));
            const interval = @as(usize, @intFromFloat(apic.hpetTicksPer100NS * 10000.0 * 1000.0));
            std.log.info("HPET @ {d} MHz for APIC Timer Calibration", .{hz / 1000 / 1000});
            apic.write(0x320, 0x10000);
            apic.write(0x3e0, 0xb);
            const duration = hpetAddr[30] + interval;
            apic.write(0x380, 0xffffffff);
            while (hpetAddr[30] < duration) {
                std.atomic.spinLoopHint();
            }
            apic.write(0x320, 0x10000);
            const count = 0xffffffff - apic.read(0x390);
            ticksPerSecond = count;
            std.log.info("{} APIC Ticks/s", .{count});
        } else {
            std.log.info("PIT @ 100 Hz for APIC Timer Calibration", .{});
            var speakerControlByte = io.inb(0x61);
            speakerControlByte &= ~@as(u8, 2);
            io.outb(0x61, speakerControlByte);
            io.outb(0x43, 0x80 | 0x00 | 0x30);
            const sleepDivisor = 1193180 / (1000000 / 10000); // 10 ms
            io.outb(0x42, sleepDivisor & 0xFF);
            io.outb(0x42, sleepDivisor >> 8);
            const pitControlByte = io.inb(0x61);
            io.outb(0x61, pitControlByte & ~@as(u8, 1));
            apic.write(0x320, 0x10000);
            apic.write(0x3e0, 0xb);
            apic.write(0x380, 0xffffffff);
            while (io.inb(0x61) & 0x20 == 0) {
                std.atomic.spinLoopHint();
            }
            apic.write(0x320, 0x10000);
            const count = 0xffffffff - apic.read(0x390);
            ticksPerSecond = count * 100;
            std.log.info("{} APIC Ticks/s", .{count * 100});
        }
    }
    apic.write(0x320, 0x20);
}

pub fn setDeadline(microsecs: usize) void {
    const t: usize = @intFromFloat(@as(f64, @floatFromInt(ticksPerSecond)) * (@as(f64, @floatFromInt(microsecs)) / 1000000.0));
    apic.write(0x380, t);
}
