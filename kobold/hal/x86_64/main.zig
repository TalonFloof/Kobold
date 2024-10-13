const std = @import("std");
const hal = @import("root").hal;
const io = @import("io.zig");

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

fn ArchInit(stackTop: usize, limine_header: *allowzero anyopaque) void {
    _ = stackTop;
    _ = limine_header;
    // TODO: Implement x86_64 init
    io.outb(0x3f8 + 1, 0x00); // Disable all interrupts
    io.outb(0x3f8 + 3, 0x80); // Enable DLAB (set baud rate divisor)
    io.outb(0x3f8 + 0, 0x01); // Set divisor to 1 (lo byte) 115200 baud
    io.outb(0x3f8 + 1, 0x00); //                  (hi byte)
    io.outb(0x3f8 + 3, 0x03); // 8 bits, no parity, one stop bit
    io.outb(0x3f8 + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    io.outb(0x3f8 + 4, 0x03);
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

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
};
