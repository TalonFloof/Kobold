const std = @import("std");
const RedBlackTree = @import("perlib").RedBlackTree;
const fs = @import("perlib").fs;
pub const Scheme = fs.Scheme;
pub const Metadata = fs.Metadata;
pub const DirEntry = fs.DirEntry;

const SchemeTreeType = RedBlackTree(*Scheme, struct {
    fn compare(a: *Scheme, b: *Scheme) std.math.Order {
        return std.mem.order(u8, a.protocolName, b.protocolName);
    }
}.compare);
