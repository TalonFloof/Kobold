const std = @import("std");
const thread = @import("thread.zig");
const Spinlock = @import("root").Spinlock;
const hal = @import("root").hal;
const RedBlackTree = @import("perlib").RedBlackTree;
const physmem = @import("root").physmem;

pub const Team = struct {
    teamID: i64,
    name: [32]u8 = [_]u8{0} ** 32,
    threads: thread.ThreadList, // Head thread is always main thread
    parent: ?*Team = null,
    aspaceLock: Spinlock = .unaquired,
    addressSpace: hal.memmodel.PageDirectory,
};

const TeamTreeType = RedBlackTree(*Team, struct {
    fn compare(a: *Team, b: *Team) std.math.Order {
        return std.math.order(a.teamID, b.teamID);
    }
}.compare);

pub var teams: TeamTreeType = .{};
pub var kteam: ?*Team = null;
pub var teamLock: Spinlock = .unaquired;
pub var nextTeamID: i64 = 1;

pub fn NewTeam(parent: ?*Team, name: []const u8) *Team {
    const old = hal.arch.intControl(false);
    teamLock.acquire();
    var team = @as(*Team, @ptrCast(@alignCast(physmem.AllocateC(@sizeOf(Team)))));

    //team.addressSpace = Memory.Paging.NewPageDirectory();
    @memcpy(@as([*]u8, @ptrFromInt(@intFromPtr(&team.name))), name);
    team.parent = parent;
    team.teamID = nextTeamID;
    nextTeamID += 1;
    const node = @as(*TeamTreeType.Node, @ptrCast(@alignCast(physmem.AllocateC(@sizeOf(TeamTreeType.Node)))));
    var entry = teams.getEntryFor(team);
    entry.set(node);
    teamLock.release();
    _ = hal.arch.intControl(old);
    return team;
}

pub fn GetTeamByID(id: i64) ?*Team {
    const old = hal.arch.intControl(false);
    teamLock.acquire();
    if (teams.root != null) {
        var x = teams.root;
        while (x) |node| {
            if (id < node.key.teamID) {
                x = node.children[0];
            } else if (id > node.key.teamID) {
                x = node.children[1];
            } else {
                return node.key;
            }
        }
    }
    teamLock.release();
    _ = hal.arch.intControl(old);
    return null;
}

fn mttreeCommand(cmd: []const u8, iter: *std.mem.SplitIterator(u8, .sequence)) void {
    _ = iter;
    _ = cmd;
    var ind = teams.inorderIterator();
    while (ind.next()) |node| {
        const team = node.key;
        std.log.debug("Team {}: {s}\n", .{ team.teamID, team.name });
        var tInd = team.threads.first;
        while (tInd) |tNode| {
            const thr: *thread.Thread = tNode.data;
            std.log.debug("  |-- Thread {}: {s}\n", .{ thr.threadID, thr.name });
            tInd = tNode.next;
        }
    }
}

pub fn Init() void {
    std.log.info("Creating Kernel Team", .{});
    kteam = NewTeam(null, "Kernel Team");
    hal.debug.NewDebugCommand("mtTree", "Prints a tree of all of the threads and teams available", &mttreeCommand);
}
