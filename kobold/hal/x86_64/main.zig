const std = @import("std");
const hal = @import("root").hal;
const physmem = @import("root").physmem;
const io = @import("io.zig");
const gdt = @import("gdt.zig");
const mem = @import("mem.zig");
const limine = @import("limine");
const elf = @import("root").elf;
const flanterm = @cImport({
    @cInclude("flanterm.h");
    @cInclude("backends/fb.h");
});

pub export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\mov %rsp, %rdi
        \\push %rax
        \\mov %cr0, %rax
        \\and $0xfb, %al
        \\or $0x22, %al
        \\mov %rax, %cr0
        \\mov %cr4, %rax
        \\or $0x600, %eax
        \\mov %rax, %cr4
        \\fninit
        \\pop %rax
        \\jmp HALInitialize
    );
}

export var moduleRequest: limine.ModuleRequest = .{};
export var fbRequest: limine.FramebufferRequest = .{};
var termCtx: ?*flanterm.flanterm_context = null;

var zeroHart: hal.HartInfo = .{};

pub fn rdmsr(index: u32) u64 {
    var low: u32 = 0;
    var high: u32 = 0;
    asm volatile ("rdmsr"
        : [lo] "={rax}" (low),
          [hi] "={rdx}" (high),
        : [ind] "{rcx}" (index),
    );
    return (@as(u64, @intCast(high)) << 32) | @as(u64, @intCast(low));
}

pub fn wrmsr(index: u32, val: u64) void {
    const low: u32 = @as(u32, @intCast(val & 0xFFFFFFFF));
    const high: u32 = @as(u32, @intCast(val >> 32));
    asm volatile ("wrmsr"
        :
        : [lo] "{rax}" (low),
          [hi] "{rdx}" (high),
          [ind] "{rcx}" (index),
    );
}

fn ArchInit(stackTop: usize, limine_header: *allowzero anyopaque) void {
    _ = limine_header;
    asm volatile ("cli");
    // TODO: Implement x86_64 init
    io.outb(0x3f8 + 1, 0x00); // Disable all interrupts
    io.outb(0x3f8 + 3, 0x80); // Enable DLAB (set baud rate divisor)
    io.outb(0x3f8 + 0, 0x01); // Set divisor to 1 (lo byte) 115200 baud
    io.outb(0x3f8 + 1, 0x00); //                  (hi byte)
    io.outb(0x3f8 + 3, 0x03); // 8 bits, no parity, one stop bit
    io.outb(0x3f8 + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    io.outb(0x3f8 + 4, 0x03);

    wrmsr(0xC0000102, @intFromPtr(&zeroHart));
    zeroHart.archData.tss.rsp[0] = stackTop;
    gdt.initialize();
    mem.init();

    if (fbRequest.response) |response| {
        const fb = response.framebuffers()[0]; // 0x292D3E
        const ansi = [_]u32{ 0x292D3E, 0xF07178, 0x62DE84, 0xFFCB6B, 0x75A1FF, 0xF580FF, 0x60BAEC, 0xABB2BF };
        const brightAnsi = [_]u32{ 0x959DCB, 0xF07178, 0xC3E88D, 0xFF5572, 0x82AAFF, 0xFFCB6B, 0x676E95, 0xFFFEFE };
        const bg: u32 = 0x292D3E;
        const fg: u32 = 0xBFC7D5;
        termCtx = flanterm.flanterm_fb_init(
            physmem.AllocateC,
            physmem.FreeC,
            @ptrFromInt(@intFromPtr(fb.address)),
            fb.width,
            fb.height,
            fb.pitch,
            fb.red_mask_size,
            fb.red_mask_shift,
            fb.green_mask_size,
            fb.green_mask_shift,
            fb.blue_mask_size,
            fb.blue_mask_shift,
            null,
            @ptrFromInt(@intFromPtr(&ansi)),
            @ptrFromInt(@intFromPtr(&brightAnsi)),
            @ptrFromInt(@intFromPtr(&bg)),
            @ptrFromInt(@intFromPtr(&fg)),
            @ptrFromInt(@intFromPtr(&bg)),
            @ptrFromInt(@intFromPtr(&fg)),
            null,
            0,
            0,
            1,
            0,
            0,
            0,
        );
    }

    if (moduleRequest.response) |response| {
        const len = response.modules().len;
        var i: usize = 0;
        for (response.modules()) |module| {
            std.log.info("Load Module ({}/{}) {s}", .{ i + 1, len, module.cmdline });
            elf.RelocateELF(@ptrCast(module.address)) catch @panic("failed!");
            i += 1;
        }
    }
}

fn ArchWriteString(_: @TypeOf(.{}), string: []const u8) error{}!usize {
    // TODO: Implement x86_64 write string
    var i: isize = 0;
    while (i < string.len) : (i += 1) {
        while ((io.inb(0x3F8 + 5) & 0x20) == 0)
            std.atomic.spinLoopHint();
        io.outb(0x3f8, string[@bitCast(i)]);
    }
    if (termCtx) |ctx| {
        flanterm.flanterm_write(ctx, string.ptr, string.len);
    }
    return string.len;
}

fn ArchGetHart() *hal.HartInfo {
    return @as(*hal.HartInfo, @ptrFromInt(rdmsr(0xC0000102)));
}

fn ArchIntControl(enable: bool) bool {
    const old = asm volatile (
        \\pushfq
        \\popq %rax
        : [o] "={rax}" (-> u64),
    );
    if (enable) {
        asm volatile ("sti");
    } else {
        asm volatile ("cli");
    }
    return old & 0x200 != 0;
}

fn ArchWaitForInt() void {
    asm volatile ("hlt");
}

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
    .getHart = ArchGetHart,
    .intControl = ArchIntControl,
    .waitForInt = ArchWaitForInt,
    .memModel = .{
        .layout = .Paging4Layer,
    },
};
