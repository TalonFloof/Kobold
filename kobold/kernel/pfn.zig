// TODO: PFN Support
const std = @import("std");

var pfn: ?[]PFNEntry = null;
var pfnBaseAddr: usize = 0;

pub enum PFNEntryType = enum(u8) {
    gpp = 0, // General Purpose Page
    reserved = 1, // Memory that will never be reclaimed
    pageTable = 2, // Memory Reserved for a branch of a page table
    pageDir = 3, // Memory Reserved for the trunk of a page table
}

pub const PFNEntry = packed struct {
    ref: usize,
    pte: u56,
    pfnType: PFNEntryType,
};

pub fn init() void {}
