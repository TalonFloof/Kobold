// TODO: PFN Support
const std = @import("std");

var pfnStart: usize = 0;
var pfnEntries: usize = 0;

pub const PFNEntry = packed struct {
    ref: usize,
    pte: u56,
    pfnType: u8,
};

pub fn init() void {}
