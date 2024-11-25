const std = @import("std");

pub const Metadata = extern struct {
    mode: u32 = 0,
    uid: u32 = 1,
    gid: u32 = 1,
    inode: usize = 0,
    nlinks: u32 = 0,
    size: usize = 0,
    blockSize: usize = 0,
    atime: i64 = 0,
    reserved1: u64 = 0,
    mtime: i64 = 0,
    reserved2: u64 = 0,
    ctime: i64 = 0,
    reserved3: u64 = 0,
    rdevmajor: u32 = 0,
    rdevminor: u32 = 0,
    blocksUsed: usize = 0,
};

pub const DirEntry = struct {
    entryType: u8,
    name: [256]u8 = [_]u8{0} ** 256,
};

pub const Scheme = struct {
    protocolName: [32]u8 = [_]u8{0} ** 32,
    open: ?*fn ([]const u8, u16, *usize) c_long = null,
    close: ?*fn (usize) c_long = null,
    read: ?*fn (usize, []u8, usize) c_long = null,
    readdir: ?*fn (usize, usize, *DirEntry) c_long = null,
    write: ?*fn (usize, []const u8, usize) c_long = null,
    truncate: ?*fn (usize, usize) c_long = null,
    lseek: ?*fn (usize, isize, usize, ?*usize) c_long = null,
    fstat: ?*fn (usize, *Metadata) c_long = null,
    fsync: ?*fn (usize) c_long = null,
    unlink: ?*fn (usize, []const u8) c_long = null,
    rmdir: ?*fn (usize, []const u8) c_long = null,
    ioctl: ?*fn (usize, usize, ?[*c]?*anyopaque) c_long = null, // ?[*c]?*anyopaque = **void
};
