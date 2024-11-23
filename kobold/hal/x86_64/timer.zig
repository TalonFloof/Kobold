const std = @import("std");
const hal = @import("../hal.zig");
const io = @import("io.zig");
const apic = @import("apic.zig");
const acpi = @import("acpi.zig");

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
pub const timer_log = std.log.scoped(.X64Timer);

pub fn init() void {
    if (ticksPerSecond == 0) {
        const hvTest = hal.archData.cpuid(0x40000000);
        if (hvTest.ebx == 0x7263694D and hvTest.ecx == 0x666F736F and hvTest.edx == 0x76482074) { // "Microsoft Hv"
            if (hal.archData.cpuid(0x40000003).edx & (1 << 8) != 0) {
                const freq = hal.archData.rdmsr(0x40000023); // HV_X64_MSR_APIC_FREQUENCY
                timer_log.info("Microsoft Hyper-V reported {} APIC Ticks/s", .{freq});
                ticksPerSecond = freq;
            } else {
                hal.HALOops("Microsoft Hyper-V doesn't give APIC Frequency, cannot calibrate LAPIC Timer");
            }
        } else {
            if ((hal.archData.cpuid(0x80000007).edx & (1 << 8)) == 0) {
                timer_log.warn("TSC isn't invariant, reverting to discrete timer for timekeeping", .{});
            }
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
                timer_log.info("HPET @ {d} MHz for APIC Timer Calibration", .{hz / 1000 / 1000});
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
            } else {
                const freq: f64 = 105000000.0 / 88.0 / 65536.0;
                timer_log.info("PIT @ ~18.2065 Hz for APIC Timer Calibration", .{});
                var speakerControlByte = io.inb(0x61);
                speakerControlByte &= ~@as(u8, 2);
                io.outb(0x61, speakerControlByte);
                io.outb(0x43, 0x80 | 0x00 | 0x30);
                const sleepDivisor = 0xffff;
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
                ticksPerSecond = @intFromFloat(@as(f64, @floatFromInt(count)) * freq);
            }
            timer_log.info("{} APIC Ticks/s", .{ticksPerSecond});
        }
    }
    apic.write(0x3e0, 0xb);
    apic.write(0x320, 0x20);
    apic.write(0x380, 0);
}

pub fn setDeadline(microsecs: u64) void {
    const t: u64 = @intFromFloat(@as(f64, @floatFromInt(ticksPerSecond)) * (@as(f64, @floatFromInt(microsecs)) / 1000000.0));
    if (t > 0xffffffff) {
        apic.write(0x380, 0xffffffff);
    } else {
        apic.write(0x380, t);
    }
}

pub fn getRemainingUs() u64 {
    const count = apic.read(0x390);
    return @intFromFloat(@as(f64, @floatFromInt(count)) * (@as(f64, @floatFromInt(ticksPerSecond)) / 1000000.0));
}
