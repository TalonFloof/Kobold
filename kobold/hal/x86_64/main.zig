const std = @import("std");
const hal = @import("../hal.zig");
const physmem = @import("root").physmem;
const io = @import("io.zig");
const gdt = @import("gdt.zig");
const idt = @import("idt.zig");
const mem = @import("mem.zig");
const limine = @import("limine");
const elf = @import("root").elf;
const acpi = @import("acpi.zig");
const apic = @import("apic.zig");
const timer = @import("timer.zig");
const hart = @import("hart.zig");
const flanterm = @cImport({
    @cInclude("flanterm.h");
    @cInclude("backends/fb.h");
});

extern fn ContextEnter(context: *allowzero void) callconv(.C) noreturn;

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

pub export fn _hartstart() callconv(.Naked) noreturn {
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
        \\jmp HartStart
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

    if (cpuid(0x80000001).edx & (@as(u32, @intCast(1)) << 20) == 0) {
        std.log.warn("WARNING!!!! Your CPU does not support the NX (No Execute) bit extension!", .{});
        std.log.warn("            This allows for programs to exploit buffer overflows to run malicious code.", .{});
        std.log.warn("            Your machine's security is at risk!", .{});
    }
    acpi.init();
    timer.init();
    hart.startSMP();

    if (moduleRequest.response) |response| {
        var len = response.modules().len;
        var i: usize = 0;
        for (response.modules()) |module| {
            if (std.mem.eql(u8, @ptrCast(module.cmdline[0..std.mem.len(module.cmdline)]), "KernelDebug")) {
                len -= 1;
                hal.debug.file.LoadDebugFile(@ptrCast(module.address));
                break;
            }
        }
        for (response.modules()) |module| {
            if (std.mem.eql(u8, @ptrCast(module.cmdline[0..std.mem.len(module.cmdline)]), "KernelDebug")) {
                continue;
            }
            std.log.info("Load Module ({}/{}) {s}", .{ i + 1, len, module.cmdline });
            //elf.RelocateELF(@ptrCast(module.address)) catch @panic("failed!");
            i += 1;
        }
    }
}

pub export fn HartStart(stackTop: usize) callconv(.C) noreturn {
    wrmsr(0xC0000102, hart.hartData);
    wrmsr(0x277, 0x0107040600070406); // Enable write combining when PAT, PCD, and PWT is set
    ArchGetHart().archData.tss.rsp[0] = stackTop;
    ArchGetHart().trapStack = stackTop;
    gdt.initialize();
    idt.fastInit();
    apic.setup();
    timer.init();
    hart.hartData = 0;
    while (true) {
        std.atomic.spinLoopHint();
    }
}

fn ArchWriteString(_: @TypeOf(.{}), string: []const u8) error{}!usize {
    if (termCtx) |ctx| {
        flanterm.flanterm_write(ctx, string.ptr, string.len);
    } else {
        var i: isize = 0;
        while (i < string.len) : (i += 1) {
            while ((io.inb(0x3F8 + 5) & 0x20) == 0)
                std.atomic.spinLoopHint();
            io.outb(0x3f8, string[@bitCast(i)]);
        }
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

    pub fn SetMode(self: *Context, kern: bool) void {
        if (kern) {
            self.cs = 0x28;
            self.ss = 0x30;
        } else {
            self.cs = 0x43;
            self.ss = 0x3b;
        }
        self.rflags = 0x202;
    }

    pub fn SetReg(self: *Context, reg: u8, val: usize) void {
        switch (reg) {
            0 => {
                self.rax = val;
            },
            1 => {
                self.rdi = val;
            },
            2 => {
                self.rsi = val;
            },
            3 => {
                self.rdx = val;
            },
            4 => {
                self.r10 = val;
            },
            5 => {
                self.r8 = val;
            },
            6 => {
                self.r9 = val;
            },
            128 => {
                self.rip = val;
            },
            129 => {
                self.rsp = val;
            },
            else => {},
        }
    }

    pub fn GetReg(self: *Context, reg: u8) usize {
        return switch (reg) {
            0 => self.rax,
            1 => self.rdi,
            2 => self.rsi,
            3 => self.rdx,
            4 => self.r10,
            5 => self.r8,
            6 => self.r9,
            128 => self.rip,
            129 => self.rsp,
            else => 0,
        };
    }

    pub fn Dump(self: *Context) void {
        std.log.debug(" rax 0x{x: <16}    rbx 0x{x: <16}    rcx 0x{x: <16}\n", .{ self.rax, self.rbx, self.rcx });
        std.log.debug(" rdx 0x{x: <16}    rsi 0x{x: <16}    rdi 0x{x: <16}\n", .{ self.rdx, self.rsi, self.rdi });
        std.log.debug(" rbp 0x{x: <16}     r8 0x{x: <16}     r9 0x{x: <16}\n", .{ self.rbp, self.r8, self.r9 });
        std.log.debug(" r10 0x{x: <16}    r11 0x{x: <16}    r12 0x{x: <16}\n", .{ self.r10, self.r11, self.r12 });
        std.log.debug(" r13 0x{x: <16}    r14 0x{x: <16}    r15 0x{x: <16}\n", .{ self.r13, self.r14, self.r15 });
        std.log.debug(" rip 0x{x: <16}    rsp 0x{x: <16} rflags 0x{x: <16}\n", .{ self.rip, self.rsp, self.rflags });
        std.log.debug(" error code: 0x{x}\n", .{self.errcode});
    }

    pub inline fn Enter(self: *Context) noreturn {
        ContextEnter(@as(*allowzero void, @ptrFromInt(@intFromPtr(self))));
    }
};

const FloatContext = struct {
    data: [512]u8 align(16) = [_]u8{0} ** 512,

    pub fn Save(self: *FloatContext) void {
        asm volatile ("fxsave64 (%rax)"
            :
            : [state] "{rax}" (&self.data),
        );
    }
    pub fn Load(self: *FloatContext) void {
        asm volatile ("fxrstor64 (%rax)"
            :
            : [state] "{rax}" (&self.data),
        );
    }
};

fn fthConvert(pte: usize, high: bool) hal.memmodel.HALPageFrame { // high set if not at 4 KiB granularity
    const frame: hal.memmodel.HALPageFrame = .{};
    const branch: bool = high and ((pte & 0x80) == 0);
    frame.valid = pte & 1;
    frame.read = if (branch) 0 else (pte & 1);
    frame.write = if (branch) 0 else ((pte >> 1) & 1);
    frame.execute = if (branch) 0 else (((~pte) >> 63) & 1);
    frame.noCache = (pte >> 4) & 1;
    frame.writeThru = (pte >> 3) & 1;
    if (high) {
        frame.writeComb = (pte >> 12) & 1;
    } else {
        frame.writeComb = (pte >> 7) & 1;
    }
    frame.highLeaf = if (high and !branch) 1 else 0;
    frame.phys(pte >> 12) & (if (high) 0xf_ffff_fffe else 0xf_ffff_ffff);
    return frame;
}

fn htfConvert(pte: hal.memmodel.HALPageFrame) usize {
    var frame: usize = 0;
    if (pte.valid == 0)
        return 0;
    if (pte.read == 0 and pte.write == 0 and pte.execute == 0) { // Branch
        frame |= 0x3; // VALID | WRITE
        frame |= pte.user << 2;
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
        if (pte.highLeaf) {
            frame |= 0x80 | (pte.writeComb << 12); // PS | PAT
        } else {
            frame |= pte.writeComb << 7;
        }
        frame |= pte.phys << 12;
    }
    return frame;
}

// This CPUID struct and function orginates from the Rise operating system
// https://github.com/davidgm94/rise/blob/main/src/lib/arch/x86/common.zig
// Rise is licensed under the 3-clause BSD License
pub const CPUID = extern struct {
    eax: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
};

pub inline fn cpuid(leaf: u32) CPUID {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var edx: u32 = undefined;
    var ecx: u32 = undefined;

    asm volatile (
        \\cpuid
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [edx] "={edx}" (edx),
          [ecx] "={ecx}" (ecx),
        : [leaf] "{eax}" (leaf),
    );

    return CPUID{
        .eax = eax,
        .ebx = ebx,
        .edx = edx,
        .ecx = ecx,
    };
}

var isShiftPressed: bool = false;

pub const unshiftedMap = [128]u8{
    0,    27,  '1', '2', '3', '4', '5', '6', '7',  '8', '9', '0',  '-',  '=', 8,   '\t',
    'q',  'w', 'e', 'r', 't', 'y', 'u', 'i', 'o',  'p', '[', ']',  '\n', 0,   'a', 's',
    'd',  'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`', 0,   '\\', 'z',  'x', 'c', 'v',
    'b',  'n', 'm', ',', '.', '/', 0,   '*', 0,    ' ', 0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    '\\', 0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
    0,    0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,    0,    0,   0,   0,
};

pub const shiftedMap = [128]u8{
    0,   27,  '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_',  '+', 8,   '\t',
    'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n', 0,   'A', 'S',
    'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0,   '|', 'Z',  'X', 'C', 'V',
    'B', 'N', 'M', '<', '>', '?', 0,   '*', 0,   ' ', 0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    '|', 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,    0,   0,   0,
};

extern fn disasm(addr: usize, str: *anyopaque) callconv(.C) usize;

fn ArchDebugGet() u8 {
    while (true) {
        var status = io.inb(0x64);
        while ((status & 1) != 0) {
            const key = io.inb(0x60);
            if ((status & 0x20) != 0) {
                status = io.inb(0x64);
                continue;
            }
            if (key == 0x2a or key == 0x36) {
                isShiftPressed = true;
            } else if (key == 0xaa or key == 0xb6) {
                isShiftPressed = false;
            } else if (key < 128) {
                const char = if (isShiftPressed) shiftedMap[key] else unshiftedMap[key];
                if (char != 0) {
                    return char;
                }
            }
            status = io.inb(0x64);
        }
        std.atomic.spinLoopHint();
    }
}

pub const Interface: hal.ArchInterface = .{
    .init = ArchInit,
    .write = ArchWriteString,
    .getHart = ArchGetHart,
    .intControl = ArchIntControl,
    .waitForInt = ArchWaitForInt,
    .setTimerDeadline = timer.setDeadline,
    .getRemainingTime = timer.getRemainingUs,
    .debugGet = ArchDebugGet,
    .debugDisasm = disasm,
    .memModel = .{
        .layout = .Paging4Layer,
        .nativeToHal = fthConvert,
        .halToNative = htfConvert,
    },
    .Context = Context,
    .FloatContext = FloatContext,
};
