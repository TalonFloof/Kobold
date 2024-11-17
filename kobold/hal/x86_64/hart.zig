const limine = @import("limine");
const std = @import("std");
const hal = @import("../hal.zig");
const physmem = @import("root").physmem;

export var smp_request: limine.SmpRequest = .{ .flags = 0 };
pub var hartData: usize = 0;

pub fn startSMP() void {
    if (smp_request.response) |response| {
        hal.hiList = @as([*]*hal.HartInfo, @ptrCast(@alignCast(physmem.AllocateC(response.cpu_count * @sizeOf(usize)))))[0..response.cpu_count];
        hal.hiList.?[0] = hal.arch.getHart();
        var hartCount: i32 = 1;
        std.log.info("{} Hart System (MultiHart Kernel)", .{hal.hiList.?.len});
        for (response.cpus()) |hart| {
            if (hart.lapic_id != response.bsp_lapic_id) {
                var hi: *hal.HartInfo = @ptrCast(@alignCast(physmem.AllocateC(@sizeOf(hal.HartInfo))));
                hal.hiList.?[@as(usize, @intCast(hartCount))] = hi;
                hi.hartID = @intCast(hartCount);
                hi.archData.apicID = hart.lapic_id;
                hartData = @intFromPtr(hi);
                @as(*align(1) u64, @ptrFromInt(@intFromPtr(hart) + @offsetOf(limine.SmpInfo, "goto_address"))).* = @intFromPtr(&hal.archData._hartstart);
                var cycles: usize = 0;
                while (hartData != 0) {
                    cycles += 1;
                    if (cycles >= 50000000) {
                        std.log.err("Hart #{} took too long (potential triple fault on hart!)", .{hartCount});
                        hal.HALOops("X86_64 HAL Initialization Failure");
                    }
                    std.atomic.spinLoopHint();
                }
                hartCount += 1;
            }
        }
    } else {
        std.log.info("1 Hart System (MultiHart Kernel)", .{});
    }
}
