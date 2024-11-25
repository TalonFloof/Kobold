const std = @import("std");

pub const DirEntry = struct {
    entryType: u8,
    name: [256]u8 = [_]u8{0} ** 256,
}

pub const Scheme = struct {
    protocolName: [32]u8 = [_]u8{0} ** 32,
    open: ?*fn ([]const u8, u16, *usize) c_long = null,
    close: ?*fn (usize) c_long = null,
    read: ?*fn (usize, []u8, usize) c_long = null,
    readdir: ?*fn (usize, usize, *DirEntry) c_long = null,
    write: ?*fn (usize, []const u8, usize) c_long = null,
    ftruncate: ?*fn (usize, usize) c_long = null,
    lseek: ?*fn (usize, isize, usize, ?*usize) c_long = null,
    fstat: ?*fn (usize, *Metadata) c_long = null,
    unlink: ?*fn (usize, []const u8) c_long = null,
    rmdir: ?*fn (usize, []const u8) c_long = null,
};
// root:/
