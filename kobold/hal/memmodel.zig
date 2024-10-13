const std = @import("std");
const hal = @import("root").hal;

// TODO: Finish This

pub const LayoutType = enum {
    FlatNoProt,
    FlatPhysProt,
    Paging,
};

hal.