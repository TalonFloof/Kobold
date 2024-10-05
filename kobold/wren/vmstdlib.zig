const std = @import("std");

pub export var errno: c_int = 0;

// memory
pub export fn memcpy(dest: *anyopaque, src: *anyopaque, n: isize) callconv(.C) *void {
    std.mem.copyForwards(u8, @as(*u8, @alignCast(dest))[0..n], @as(*u8, @alignCast(src))[0..n]);
    return @as(*void, @ptrCast(dest));
}

pub export fn memset(dest: *anyopaque, c: u8, n: isize) callconv(.C) *void {
    @memset(@as(*u8, @alignCast(dest))[0..n], c);
}

pub export fn memmove(dest: *anyopaque, src: *anyopaque, n: isize) callconv(.C) *void {
    @memcpy(@as(*u8, @alignCast(dest))[0..n], @as(*u8, @alignCast(src))[0..n]) catch return;
}

pub export fn memcmp(s1: *anyopaque, s2: *anyopaque, n: isize) callconv(.C) c_int {
    switch (std.mem.order(@as(*u8, @alignCast(s1))[0..n], @as(*u8, @alignCast(s2))[0..n])) {
        .lt => return -1,
        .gt => return 1,
        .eq => return 0,
    }
    unreachable;
}
// string
pub export fn strlen(s: *anyopaque) callconv(.C) usize {
    return std.mem.len(s);
}
// string - conversion
pub export fn strtod(s: [*c]u8, e: *allowzero [*c]u8) callconv(.C) f64 {
    if (@as(usize, @intFromPtr(e)) != 0) {} else {
        return try std.fmt.parseFloat(s[0..std.mem.len(s)]);
    }
}
// math
pub export fn abs(x: c_int) callconv(.C) c_int {
    return @abs(x);
}
pub export fn fabs(x: f64) callconv(.C) f64 {
    return @abs(x);
}
pub export fn log(x: f64) callconv(.C) f64 {
    return @log(x);
}
pub export fn exp(x: f64) callconv(.C) f64 {
    return @exp(x);
}
pub export fn log2(x: f64) callconv(.C) f64 {
    return @log2(x);
}
pub export fn floor(x: f64) callconv(.C) f64 {
    return @floor(x);
}
pub export fn round(x: f64) callconv(.C) f64 {
    return @round(x);
}
pub export fn ceil(x: f64) callconv(.C) f64 {
    return @ceil(x);
}
pub export fn fmax(x: f64, y: f64) callconv(.C) f64 {
    return @max(x, y);
}
pub export fn fmin(x: f64, y: f64) callconv(.C) f64 {
    return @min(x, y);
}
pub export fn pow(x: f64, y: f64) callconv(.C) f64 {
    return std.math.pow(f64, x, y);
}
pub export fn fmod(x: f64, y: f64) callconv(.C) f64 {
    return std.math.mod(f64, x, y);
}
pub export fn modf(x: f64, y: *allowzero f64) callconv(.C) f64 {
    const r = std.math.modf(x);
    if (@as(usize, @intFromPtr(y)) != 0) {
        y.* = r.fpart;
    }
    return r.ipart;
}
// math - trig
pub export fn cos(x: f64) callconv(.C) f64 {
    return @cos(x);
}
pub export fn acos(x: f64) callconv(.C) f64 {
    return std.math.acos(x);
}
pub export fn sin(x: f64) callconv(.C) f64 {
    return @sin(x);
}
pub export fn asin(x: f64) callconv(.C) f64 {
    return std.math.asin(x);
}
pub export fn tan(x: f64) callconv(.C) f64 {
    return @tan(x);
}
pub export fn atan(x: f64) callconv(.C) f64 {
    return std.math.atan(x);
}
pub export fn atan2(y: f64, x: f64) callconv(.C) f64 {
    return std.math.atan2(y, x);
}
// math - root
pub export fn sqrt(x: f64) callconv(.C) f64 {
    return @sqrt(x);
}
pub export fn cbrt(x: f64) callconv(.C) f64 {
    return std.math.cbrt(x);
}

pub export fn isnan(x: f64) callconv(.C) bool {
    return std.math.isNan(x);
}
pub export fn isinf(x: f64) callconv(.C) bool {
    return std.math.isInf(x);
}
