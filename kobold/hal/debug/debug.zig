const std = @import("std");
const physmem = @import("root").physmem;
const hal = @import("root").hal;
pub const file = @import("debugFile.zig");

const DebugCommand = struct {
    name: []const u8,
    desc: []const u8,
    func: *const fn (cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void,
};

const DebugCommandList = std.DoublyLinkedList(DebugCommand);

var commandList: DebugCommandList = .{};

pub fn NewDebugCommand(name: []const u8, desc: []const u8, func: *const fn (cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void) void {
    var dbgCmd: *DebugCommandList.Node = @alignCast(@ptrCast(physmem.Allocate(@sizeOf(DebugCommandList.Node), @alignOf(DebugCommandList.Node)).?));
    dbgCmd.data.name = name;
    dbgCmd.data.desc = desc;
    dbgCmd.data.func = func;
    commandList.append(dbgCmd);
}

pub fn EnterDebugger() void {
    while (true) {
        std.log.debug("kdbg> ", .{});
        var buf: [256]u8 = [_]u8{0} ** 256;
        var i: usize = 0;
        while (true) {
            const key: u8 = hal.arch.debugGet.?();
            if (key == 8 and i > 0) {
                std.log.debug("\x08 \x08", .{});
            } else if ((key == '\n') or (key != 8 and i < 256)) {
                std.log.debug("{c}", .{key});
            }
            if (key == '\n') {
                break;
            }
            if (key == 8) {
                if (i > 0) {
                    i -= 1;
                }
            } else {
                if (i < 256) {
                    buf[i] = key;
                    i += 1;
                }
            }
        }
        var iter = std.mem.split(u8, buf[0..i], " ");
        const cmd = iter.next().?;
        if (std.mem.eql(u8, cmd, "continue")) {
            break;
        }
        var c = commandList.first;
        while (c != null) {
            if (std.mem.eql(u8, cmd, c.?.data.name)) {
                c.?.data.func(cmd, &iter);
                break;
            }
            c = c.?.next;
        }
        if (c == null) {
            std.log.debug("{s}?\n", .{cmd});
        }
    }
}

pub fn PrintBacktrace(start: usize) void {
    std.log.debug("Stack Backtrace\n", .{});
    var it = std.debug.StackIterator.init(start, null);
    while (it.next()) |frame| {
        if (frame == 0) {
            break;
        }
        std.log.debug("  \x1b[1;30m0x{x:0>16}\x1b[0m ", .{frame});
        file.PrintSymbolName(frame);
        std.log.debug("\n", .{});
    }
}

pub fn helpCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    _ = iter;
    std.log.debug("List of available commands:\n continue - Exits the debugger and continues execution\n", .{});
    var c = commandList.first;
    while (c != null) {
        std.log.debug(" {s} - {s}\n", .{ c.?.data.name, c.?.data.desc });
        c = c.?.next;
    }
}

pub fn backtraceCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    _ = iter;
    PrintBacktrace(@returnAddress());
}

pub fn sbCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    if (iter.peek() != null) {
        const sym = iter.rest();
        const range = file.GetSymbolRange(sym);
        if (range.start == 0 and range.end == 0) {
            std.log.debug("Symbol \"{s}\" is not within the debug file\n", .{sym});
            return;
        }
        const slice = @as([*]const u8, @ptrFromInt(range.start))[0..range.end];
        var chunks = std.mem.window(u8, slice, 16, 16);
        while (chunks.next()) |window| {
            const address = (@intFromPtr(slice.ptr) + 0x10 * (chunks.index orelse 0) / 16) - 0x10;
            std.log.debug("{x:0>[1]}  ", .{ address, @sizeOf(usize) * 2 });
            for (window, 0..) |byte, index| {
                std.log.debug("{X:0>2} ", .{byte});
                if (index == 7) std.log.debug(" ", .{});
            }
            std.log.debug(" ", .{});
            if (window.len < 16) {
                var missing_columns = (16 - window.len) * 3;
                if (window.len < 8) missing_columns += 1;
                for (0..missing_columns) |_| {
                    std.log.debug(" ", .{});
                }
            }
            for (window) |byte| {
                if (std.ascii.isPrint(byte)) {
                    std.log.debug("{c}", .{byte});
                } else {
                    std.log.debug(".", .{});
                }
            }
            std.log.debug("\n", .{});
        }
    } else {
        std.log.debug("Usage: sb <symbolName>\n", .{});
    }
}

pub fn snCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    if (iter.peek() != null) {
        const sym = iter.rest();
        const range = file.GetSymbolRange(sym);
        if (range.start == 0 and range.end == 0) {
            std.log.debug("Symbol \"{s}\" is not within the debug file\n", .{sym});
            return;
        }
        const slice = @as([*]const u8, @ptrFromInt(range.start))[0..range.end];
        if (slice.len == 1) {
            std.log.debug("u8 {s} = 0x{x}\n", .{ sym, @as(*u8, @ptrFromInt(range.start)).* });
        } else if (slice.len == 2) {
            std.log.debug("u16 {s} = 0x{x}\n", .{ sym, @as(*u16, @ptrFromInt(range.start)).* });
        } else if (slice.len == 4) {
            std.log.debug("u32 {s} = 0x{x}\n", .{ sym, @as(*u32, @ptrFromInt(range.start)).* });
        } else if (slice.len == 8) {
            std.log.debug("u64 {s} = 0x{x}\n", .{ sym, @as(*u64, @ptrFromInt(range.start)).* });
        } else {
            std.log.debug("A symbol with {} bytes does not translate to a number, use sb to dump the data instead\n", .{slice.len});
        }
    } else {
        std.log.debug("Usage: sn <symbolName>\n", .{});
    }
}

pub fn siCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    if (hal.arch.debugDisasm) |disasm| {
        const sym = iter.rest();
        const range = file.GetSymbolRange(sym);
        if (range.start == 0 and range.end == 0) {
            std.log.debug("Symbol \"{s}\" is not within the debug file\n", .{sym});
            return;
        }
        const end = range.start + range.end;
        var buf: [256]u8 = [_]u8{0} ** 256;
        var i = range.start;
        while (i < end) {
            std.log.debug("{x}: ", .{i});
            i = disasm(i, &buf);
            std.log.debug("{s}\n", .{@as([*c]u8, @ptrFromInt(@intFromPtr(&buf)))});
            @memset(@as([*]u8, @alignCast(@ptrCast(&buf)))[0..256], 0);
        }
    } else {
        std.log.debug("This architecture does not have an available disassembler\n", .{});
    }
}

pub fn nsCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    if (iter.next()) |addrStr| {
        const addr = std.fmt.parseInt(usize, addrStr, 0) catch 0;
        std.log.debug("0x{x} = ", .{addr});
        file.PrintSymbolName(addr);
        std.log.debug("\n", .{});
    } else {
        std.log.debug("Usage: ns <address>\n", .{});
    }
}

pub fn symsCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = cmd;
    if (iter.peek() != null) {
        const sym = iter.rest();
        var it = std.mem.splitAny(u8, sym, ":");
        const fname = it.next().?;
        const sname = it.rest();
        if (file.debugFileAddr != null) {
            var f: usize = 0;
            while (f < file.debugFileCount) : (f += 1) {
                const fileEntry: *file.DebugFileEntry = @ptrFromInt(@intFromPtr(file.debugFileAddr) + (f * @sizeOf(file.DebugFileEntry)));
                const fileName = @as([*c]const u8, @ptrFromInt(@intFromPtr(file.debugFileAddr) + fileEntry.nameOffset));
                if (std.mem.startsWith(u8, fileName[0..std.mem.len(fileName)], fname)) {
                    var symbol: usize = 0;
                    while (symbol < fileEntry.size) : (symbol += 1) {
                        const symbolEntry: *file.DebugSymbolEntry = @ptrFromInt(@intFromPtr(file.debugFileAddr) + @as(usize, @intCast(fileEntry.offset)) + (symbol * @sizeOf(file.DebugSymbolEntry)));
                        const symName = @as([*c]const u8, @ptrFromInt(@intFromPtr(file.debugFileAddr) + symbolEntry.nameOffset));
                        if (std.mem.startsWith(u8, symName[0..std.mem.len(symName)], sname)) {
                            std.log.debug("[0x{x}-0x{x}] {s}:{s}\n", .{ symbolEntry.symAddr, symbolEntry.symAddr + @as(u64, @intCast(symbolEntry.symSize)), fileName, symName });
                        }
                    }
                }
            }
        }
    } else {
        std.log.debug("Usage: syms <file>:[symbol]\nNote: Does not have to be the entire name of file/symbol\n", .{});
    }
}

pub fn DebugInit() void {
    NewDebugCommand("help", "Prints this message", &helpCommand);
    NewDebugCommand("bt", "Prints a Stack Backtrace", &backtraceCommand);
    NewDebugCommand("sb", "Dump hex data (in byte sizes) within a given symbol", &sbCommand);
    NewDebugCommand("sn", "Dump number within a given symbol", &snCommand);
    NewDebugCommand("si", "Disassembles the given symbol", &siCommand);
    NewDebugCommand("ns", "Retrieves the nearest symbol to a given address", &nsCommand);
    NewDebugCommand("syms", "Searches for symbols and lists them out", &symsCommand);
}
