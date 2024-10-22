const std = @import("std");
const hal = @import("root").hal;
const physmem = @import("root").physmem;
const io = @import("io.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
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
    idt.initialize();
    mem.init();

    if (fbRequest.response) |response| {
        const fb = response.framebuffers()[0]; // 0x292D3E
        const ansi = [_]u32{ 0x292D3E, 0xF07178, 0x62DE84, 0xFFCB6B, 0x75A1FF, 0xF580FF, 0x60BAEC, 0xABB2BF };
        const brightAnsi = [_]u32{ 0x959DCB, 0xF07178, 0xC3E88D, 0xFF5572, 0x82AAFF, 0xFFCB6B, 0x676E95, 0xFFFEFE };
        const bg: u32 = 0x0e0f15;
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

const Context = packed struct {
    r15: u64 = 0,
    r14: u64 = 0,
    r13: u64 = 0,
    r12: u64 = 0,
    r11: u64 = 0,
    r10: u64 = 0,
    r9: u64 = 0,
    r8: u64 = 0,
    rbp: u64 = 0,
    rdi: u64 = 0,
    rsi: u64 = 0,
    rdx: u64 = 0,
    rcx: u64 = 0,
    rbx: u64 = 0,
    rax: u64 = 0,
    errcode: u64 = 0,
    rip: u64 = 0,
    cs: u64 = 0,
    rflags: u64 = 0x202,
    rsp: u64 = 0,
    ss: u64 = 0,

    pub fn Dump(self: *Context) void {
        std.log.debug(" rax 0x{x: <16}    rbx 0x{x: <16}    rcx 0x{x: <16}\n", .{ self.rax, self.rbx, self.rcx });
        std.log.debug(" rdx 0x{x: <16}    rsi 0x{x: <16}    rdi 0x{x: <16}\n", .{ self.rdx, self.rsi, self.rdi });
        std.log.debug(" rbp 0x{x: <16}     r8 0x{x: <16}     r9 0x{x: <16}\n", .{ self.rbp, self.r8, self.r9 });
        std.log.debug(" r10 0x{x: <16}    r11 0x{x: <16}    r12 0x{x: <16}\n", .{ self.r10, self.r11, self.r12 });
        std.log.debug(" r13 0x{x: <16}    r14 0x{x: <16}    r15 0x{x: <16}\n", .{ self.r13, self.r14, self.r15 });
        std.log.debug(" rip 0x{x: <16}    rsp 0x{x: <16} rflags 0x{x: <16}\n", .{ self.rip, self.rsp, self.rflags });
        std.log.debug(" error code: 0x{x}\n", .{self.errcode});
    }
};

//const NativePTEEntry = packed struct {
//    valid: u1 = 0, // 0
//    write: u1 = 0, // 1
//    user: u1 = 0, // 2
//    writeThrough: u1 = 0, // 3
//    cacheDisable: u1 = 0, // 4
//    reserved1: u2 = 0, // 5-6
//    pat: u1 = 0, // 7
//    reserved2: u4 = 0, // 8-11
//    phys: u51 = 0,
//    noExecute: u1 = 0,
//};

fn fthConvert(pte: usize, high: bool) hal.memmodel.HALPageFrame { // high set if not at 4 KiB granularity
    const frame: hal.memmodel.HALPageFrame = .{};
    const branch: bool = high and ((pte & 0x80) == 0);
    frame.valid = pte & 1
    frame.read = if(branch) 0 else (pte & 1);
    frame.write = if(branch) 0 else ((pte >> 1) & 1);
    frame.execute = if(branch) 0 else (((~pte) >> 63) & 1);
    frame.noCache = (pte >> 4) & 1;
    frame.writeThru = (pte >> 3) & 1;
    if(high) {
        frame.writeComb = (pte >> 12) & 1;
    } else {
        frame.writeComb = (pte >> 7) & 1;
    }
    frame.highLeaf = if(high and !branch) 1 else 0;
    frame.phys (pte >> 12) & (if(high) 0xf_ffff_fffe else 0xf_ffff_ffff);
    return frame;
}

fn htfConvert(pte: hal.memmodel.HALPageFrame) usize {
    var frame: usize = 0;
    if(pte.valid == 0)
        return 0;
    if(pte.read == 0 and pte.write == 0 and pte.execute == 0) { // Branch
        frame |= 0x3; // VALID | WRITE
        frame |= pte.user << 2;
        frame |= ((~pte.execute) & 1) << 63;
        frame |= pte.noCache << 4;
        frame |= pte.writeThru << 3;
        frame |= pte.writeComb << 12;
        frame |= pte.phys << 12;
    } else { // Leaf
        frame |= 0x1; // VALID
        frame |= pte.write << 1;
        frame |= ((~pte.execute) & 1) << 63;
        frame |= pte.noCache << 4;
        frame |= pte.writeThru << 3;
        if(pte.highLeaf) {
            frame |= 0x80 | (pte.writeComb << 12); // PS | PAT
        } else {
            frame |= pte.writeComb << 7;
        }
        frame |= pte.phys << 12;
    }
    return frame;
}

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
    .getHart = ArchGetHart,
    .intControl = ArchIntControl,
    .waitForInt = ArchWaitForInt,
    .memModel = .{
        .layout = .Paging4Layer,
        .nativeToHal = fthConvert,
        .halToNative = htfConvert,
    },
    .Context = Context,
};
