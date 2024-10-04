const std = @import("std");

pub export fn memcpy(dest: *anyopaque, src: *anyopaque, n: isize) *void {
    std.mem.copyForwards(u8, @as(*u8, @alignCast(dest))[0..n], @as(*u8, @alignCast(src))[0..n]);
    return @as(*void, @ptrCast(dest));
}

pub export fn memset(dest: *anyopaque, c: u8, n: isize) *void {
    @memset(@as(*u8, @alignCast(dest))[0..n], c);
}

pub export fn memmove(dest: *anyopaque, src: *anyopaque, n: isize) *void {
    @memcpy(@as(*u8, @alignCast(dest))[0..n], @as(*u8, @alignCast(src))[0..n]) catch return;
}

pub export fn memcmp(s1: *anyopaque, s2: *anyopaque, n: isize) c_int {
    switch (std.mem.order(@as(*u8, @alignCast(s1))[0..n], @as(*u8, @alignCast(s2))[0..n])) {
        .lt => return -1,
        .gt => return 1,
        .eq => return 0,
    }
    unreachable;
}

pub export fn strlen(s: *anyopaque) usize {
    return std.mem.len(s);
}
