const std = @import("std");
const hal = @import("root").hal;
const io = @import("io.zig");
const gdt = @import("gdt.zig");
const mem = @import("mem.zig");

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
}

fn ArchWriteString(_: @TypeOf(.{}), string: []const u8) error{}!usize {
    // TODO: Implement x86_64 write string
    var i: isize = 0;
    while (i < string.len) : (i += 1) {
        while ((io.inb(0x3F8 + 5) & 0x20) == 0)
            std.atomic.spinLoopHint();
        io.outb(0x3f8, string[@bitCast(i)]);
    }
    return string.len;
}

fn ArchGetHart() *hal.HartInfo {
    return @as(*hal.HartInfo, @ptrFromInt(rdmsr(0xC0000102)));
}

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
    .getHart = ArchGetHart,
    .memModel = .{
        .layout = .Paging4Layer,
    },
};
