pub const Semaphore = struct {
    semID: i64,
    teamID: i64,
    name: [32]u8 = [_]u8{0} ** 32,
    threadCount: usize,
};
