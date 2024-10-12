const std = @import("std");

pub const ELFError = error{
    InvalidMagic,
};

pub fn RelocateELF(elf: *anyopaque) ELFError!void {
    const header: *std.elf.Ehdr = @ptrCast(@alignCast(elf));
    if (!std.mem.eql(u8, header.e_ident[0..4], "\x7fELF"))
        return ELFError.InvalidMagic;
}
