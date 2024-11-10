const std = @import("std");
const hal = @import("../hal.zig");

pub var lapic_ptr: usize = 0;
pub var ioapic_regSelect: *allowzero volatile u32 = @as(*allowzero volatile u32, @ptrFromInt(0));
pub var ioapic_ioWindow: *allowzero volatile u32 = @as(*allowzero volatile u32, @ptrFromInt(0));

const x2apic_register_base: usize = 0x800;

pub var ioapic_redirect: [24]u8 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23 };
pub var ioapic_activelow: [24]bool = [_]bool{false} ** 24;
pub var ioapic_leveltrig: [24]bool = [_]bool{false} ** 24;
pub var hpetPeriod: f64 = 0;
pub var hpetNSPeriod: f64 = 0;
pub var hpetTicksPer100NS: f64 = 0;
pub var hpetHZ: f64 = 0;

inline fn x2apicSupport() bool {
    return (hal.archData.cpuid(0x1).ecx & (@as(u32, @intCast(1)) << 21)) != 0;
}

pub fn setup() void {
    if (x2apicSupport()) {
        if (hal.arch.getHart().hartID == 0) {
            lapic_ptr = 0xffffffff;
            std.log.info("X2APIC is enabled or required by system, switching to X2APIC operations", .{});
        }
        hal.archData.wrmsr(0x1b, (hal.archData.rdmsr(0x1b) | 0x800 | 0x400)); // Enable the X2APIC
    } else {
        hal.archData.wrmsr(0x1b, (hal.archData.rdmsr(0x1b) | 0x800) & ~(@as(u64, 1) << @as(u64, 10))); // Enable the XAPIC
        if (hal.arch.getHart().hartID == 0) {
            lapic_ptr = (hal.archData.rdmsr(0x1b) & 0xfffff000) + 0xffff800000000000; // Get the Pointer
        }
    }
    write(0xf0, 0x1f0); // Enable Spurious Interrupts (This starts up the Local APIC)
    for (0..24) |i| {
        if (ioapic_redirect[i] != 0 and ioapic_redirect[i] != 0xff and ioapic_redirect[i] != 8) {
            const val1: u64 = if (ioapic_leveltrig[i]) @as(u64, @intCast(1)) << 15 else 0;
            const val2: u64 = if (ioapic_activelow[i]) @as(u64, @intCast(1)) << 13 else 0;
            writeIo64(0x10 + (2 * i), (ioapic_redirect[i] + 0x20) | val1 | val2);
        }
    }
}

pub fn read(reg: usize) u64 {
    if (lapic_ptr == 0xffffffff) { // X2APIC
        return hal.archData.rdmsr(@as(u32, @intCast(x2apic_register_base + (reg / 16))));
    } else {
        return @as(u64, @intCast(@as(*volatile u32, @ptrFromInt(lapic_ptr + reg)).*));
    }
}

pub fn write(reg: usize, val: u64) void {
    if (lapic_ptr == 0xffffffff) { // X2APIC
        hal.archData.wrmsr(@as(u32, @intCast(x2apic_register_base + (reg / 16))), val);
    } else {
        @as(*volatile u32, @ptrFromInt(lapic_ptr + reg)).* = @as(u32, @intCast(val & 0xFFFFFFFF));
    }
}

pub fn readIo32(reg: usize) u32 {
    ioapic_regSelect.* = @as(u32, @intCast(reg));
    return ioapic_ioWindow.*;
}

pub fn writeIo32(reg: usize, val: u32) void {
    ioapic_regSelect.* = @as(u32, @intCast(reg));
    ioapic_ioWindow.* = val;
}

pub fn readIo64(reg: usize) u64 {
    const low: u64 = @as(u64, @intCast(readIo32(reg)));
    const high: u64 = @as(u64, @intCast(readIo32(reg + 1))) << 32;
    return high | low;
}

pub fn writeIo64(reg: usize, val: u64) void {
    writeIo32(reg, @as(u32, @intCast(val & 0xFFFFFFFF)));
    writeIo32(reg + 1, @as(u32, @intCast((val >> 32) & 0xFFFFFFFF)));
}
