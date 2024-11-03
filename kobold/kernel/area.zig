pub const Area = packed struct {
    addr: usize,
    size: usize,
    write: u1,
    exec: u1,
};
