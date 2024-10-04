const std = @import("std");
// memory
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
// string
pub export fn strlen(s: *anyopaque) usize {
    return std.mem.len(s);
}
// math
pub export fn log2(x: f64) f64 {
    return @log2(x);
}
pub export fn round(x: f64) f64 {
    return @round(x);
}
pub export fn fmax(x: f64, y: f64) f64 {
    return @max(x,y);
}
pub fn export fmin(x: f64, y: f64) f64 {
    return @min(x,y);
}
pub export fn pow(x: f64, y: f64) f64 {
    return std.math.pow(f64,x,y);
}
pub export fn modf(x: f64, y: f64) f64 {
    return std.math.mod(f64,x,y);
}
pub export fn modf(x: f64, y: *allowzero f64) f64 {
    var r = std.math.modf(x);
    if(@as(usize, @ptrToInt(y)) != 0) {
        y.* = r.fpart;
    }
    return r.ipart;
}
pub fn export log(x: f64) f64 {
    return @log(x);
}
pub fn export exp(x: f64) f64 {
    return @exp(x);
}
// math - trig
pub fn export cos(x: f64) f64 {
    return @cos(x);
}
pub fn export acos(x: f64) f64 {
    return std.math.acos(x);
}
pub fn export sin(x: f64) f64 {
    return @sin(x);
}
pub fn export asin(x: f64) f64 {
    return std.math.asin(x);
}
pub fn export tan(x: f64) f64 {
    return @tan(x);
}
pub fn export atan(x: f64) f64 {
    return std.math.atan(x);
}
pub fn export atan2(y: f64, x: f64) f64 {
    return std.math.atan2(y,x);
}
// math - root
pub fn export sqrt(x: f64) f64 {
    return @sqrt(x);
}
pub fn export cbrt(x: f64) f64 {
    return std.math.cbrt(x);
}