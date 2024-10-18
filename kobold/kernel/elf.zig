const std = @import("std");
const builtin = @import("builtin");
const hal = @import("root").hal;
const physmem = @import("root").physmem;

pub const ELFError = error{
    InvalidMagic,
    MismatchedArch,
    UnrecognizedRelocation,
    MemoryModelIncompat,
    NotRelocatable,
    UnsupportedArch,
};

pub const kelf_log = std.log.scoped(.KernelELF);

pub fn RelocateELF(elf: *anyopaque) ELFError!void {
    const header: *std.elf.Ehdr = @ptrCast(@alignCast(elf));
    if (!std.mem.eql(u8, header.e_ident[0..4], "\x7fELF"))
        return ELFError.InvalidMagic;
    if (header.e_type != .REL) {
        return ELFError.NotRelocatable;
    }
    var i: usize = 0;
    while (i < header.e_shnum) : (i += 1) {
        const entry: *std.elf.Shdr = @as(*std.elf.Shdr, @ptrFromInt(@intFromPtr(elf) + header.e_shoff + (i * @as(usize, @intCast(header.e_shentsize)))));
        if (entry.sh_type == 8) {
            entry.sh_addr = @intFromPtr(physmem.Allocate(entry.sh_size, 0));
        } else {
            entry.sh_addr = @intFromPtr(elf) + entry.sh_offset;
        }
    }
    i = 0;
    while (i < header.e_shnum) : (i += 1) {
        const entry: *std.elf.Shdr = @as(*std.elf.Shdr, @ptrFromInt(@intFromPtr(elf) + header.e_shoff + (i * @as(usize, @intCast(header.e_shentsize)))));
        if (entry.sh_type != 4) {
            continue;
        }
        const relTable = @as([*]std.elf.Rela, @ptrFromInt(entry.sh_addr))[0..(entry.sh_size / @sizeOf(std.elf.Rela))];
        const targetSection: *std.elf.Shdr = @as(*std.elf.Shdr, @ptrFromInt(@intFromPtr(elf) + header.e_shoff + (entry.sh_info * @as(usize, @intCast(header.e_shentsize)))));
        const symbolSection: *std.elf.Shdr = @as(*std.elf.Shdr, @ptrFromInt(@intFromPtr(elf) + header.e_shoff + (entry.sh_link * @as(usize, @intCast(header.e_shentsize)))));
        const symTable = @as([*]std.elf.Sym, @ptrFromInt(symbolSection.sh_addr))[0 .. symbolSection.sh_size / @sizeOf(std.elf.Sym)];
        for (0..relTable.len) |rela| {
            const target: usize = relTable[rela].r_offset +% targetSection.sh_addr;
            const sym: usize = relTable[rela].r_info >> 32;
            const symValue: usize = symTable[sym].st_value;
            const convAddend: usize = @bitCast(@as(isize, @intCast(relTable[rela].r_addend)));
            switch (builtin.cpu.arch) {
                .riscv64 => {
                    switch (@as(std.elf.R_RISCV, @enumFromInt(@as(u32, @intCast(relTable[rela].r_info & 0xFF))))) {
                        .@"64" => {
                            const final: usize = symValue +% convAddend;
                            @as(*usize, @ptrFromInt(target)).* = final;
                        },
                        .CALL_PLT => {
                            // calculate the offset first
                            const final: usize = symValue +% convAddend -% target;
                            const uInst: *u32 = @ptrFromInt(target);
                            const iInst: *u32 = @ptrFromInt(target + 4);
                            uInst.* = @as(u32, @truncate(final & 0xFFFFF000)) | (uInst.* & 0xFFF);
                            iInst.* = (@as(u32, @truncate(final & 0xFFF)) << 20) | (iInst.* & 0xFFFFF);
                        },
                        .PCREL_HI20 => {
                            // calculate the offset first
                            const final: usize = symValue +% convAddend -% target;
                            const uInst: *u32 = @ptrFromInt(target);
                            uInst.* = @as(u32, @truncate(final & 0xFFFFF000)) | (uInst.* & 0xFFF);
                        },
                        .PCREL_LO12_I => {
                            // calculate the offset first
                            const final: usize = symValue +% convAddend -% target;
                            const iInst: *u32 = @ptrFromInt(target);
                            iInst.* = (@as(u32, @truncate(final & 0xFFF)) << 20) | (iInst.* & 0xFFFFF);
                        },
                        else => |x| {
                            kelf_log.warn("Encountered Unsupported Relocation {s}, skipping", .{@tagName(x)});
                        },
                    }
                },
                .x86_64 => {
                    switch (@as(std.elf.R_X86_64, @enumFromInt(@as(u32, @intCast(relTable[rela].r_info & 0xFFFFFFFF))))) {
                        .@"64" => {
                            @as(*align(1) u64, @ptrFromInt(target)).* = symValue +% convAddend;
                        },
                        else => |x| {
                            kelf_log.warn("Encountered Unsupported Relocation {s}, skipping", .{@tagName(x)});
                        },
                    }
                },
                else => return ELFError.UnsupportedArch,
            }
        }
    }
}
