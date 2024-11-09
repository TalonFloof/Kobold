const std = @import("std");

pub const DebugFileEntry = struct {
    offset: u32 align(1),
    size: u32 align(1),
    nameOffset: u32 align(1),
};

pub const DebugSymbolEntry = struct {
    symAddr: u64 align(1), // 8
    symSize: u32 align(1), // 4
    nameOffset: u32 align(1), // 4
};

pub var debugFileAddr: ?*anyopaque = null;
pub var debugFileCount: usize = 0;

pub fn LoadDebugFile(p: *anyopaque) void {
    const s = @as([*]const u8, @ptrCast(p));
    if (!std.mem.eql(u8, s[0..8], "\x89KbldDbg")) {
        std.log.warn("Debug File has invalid magic number, data will not be used!", .{});
        return;
    }
    debugFileAddr = @ptrFromInt(@intFromPtr(p) + 16);
    debugFileCount = @intCast(@as(*u16, @ptrFromInt(@intFromPtr(p) + 8)).*);
}

pub fn PrintSymbolName(a: usize) void {
    var addr = a;
    if (debugFileAddr != null) {
        var iter: usize = 0;
        while (iter < 2) : (iter += 1) {
            if (iter == 1) {
                addr = addr - 1;
            }
            var file: usize = 0;
            while (file < debugFileCount) : (file += 1) {
                const fileEntry: *DebugFileEntry = @ptrFromInt(@intFromPtr(debugFileAddr) + (file * @sizeOf(DebugFileEntry)));
                var symbol: usize = 0;
                while (symbol < fileEntry.size) : (symbol += 1) {
                    const symbolEntry: *DebugSymbolEntry = @ptrFromInt(@intFromPtr(debugFileAddr) + @as(usize, @intCast(fileEntry.offset)) + (symbol * @sizeOf(DebugSymbolEntry)));
                    if (addr >= symbolEntry.symAddr and addr < symbolEntry.symAddr + @as(u64, @intCast(symbolEntry.symSize))) {
                        std.log.debug("<{s}:{s}+0x{x}/{x}>", .{
                            @as([*c]const u8, @ptrFromInt(@intFromPtr(debugFileAddr) + fileEntry.nameOffset)),
                            @as([*c]const u8, @ptrFromInt(@intFromPtr(debugFileAddr) + symbolEntry.nameOffset)),
                            @as(u64, @intCast(a)) - symbolEntry.symAddr,
                            symbolEntry.symSize,
                        });
                        return;
                    }
                }
            }
        }
    }
    std.log.debug("<?:?+?/?>", .{});
}

pub fn GetSymbolRange(name: []const u8) std.bit_set.Range {
    var iter = std.mem.splitAny(u8, name, ":");
    const fname = iter.next().?;
    const sname = iter.rest();
    if (debugFileAddr != null) {
        var file: usize = 0;
        while (file < debugFileCount) : (file += 1) {
            const fileEntry: *DebugFileEntry = @ptrFromInt(@intFromPtr(debugFileAddr) + (file * @sizeOf(DebugFileEntry)));
            const fileName = @as([*c]const u8, @ptrFromInt(@intFromPtr(debugFileAddr) + fileEntry.nameOffset));
            if (std.mem.eql(u8, fileName[0..std.mem.len(fileName)], fname)) {
                var symbol: usize = 0;
                while (symbol < fileEntry.size) : (symbol += 1) {
                    const symbolEntry: *DebugSymbolEntry = @ptrFromInt(@intFromPtr(debugFileAddr) + @as(usize, @intCast(fileEntry.offset)) + (symbol * @sizeOf(DebugSymbolEntry)));
                    const symName = @as([*c]const u8, @ptrFromInt(@intFromPtr(debugFileAddr) + symbolEntry.nameOffset));
                    if (std.mem.eql(u8, symName[0..std.mem.len(symName)], sname)) {
                        return .{
                            .start = @intCast(symbolEntry.symAddr),
                            .end = symbolEntry.symSize,
                        };
                    }
                }
                return .{ .start = 0, .end = 0 };
            }
        }
    }
    return .{ .start = 0, .end = 0 };
}
