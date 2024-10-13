const std = @import("std");
const builtin = @import("builtin");

pub const Arch = enum {
    riscv64,
    riscv32,
    arm64,
    arm,
    x86_64,
    i386,
};

pub const Board = enum {
    qemu_riscv64,
    qemu_riscv32,
    qemu_arm64,
    versatilepb_arm,
    pc_x86_64,
    pc_i386,
};

pub fn getBoard(b: *std.Build) !Board {
    return b.option(Board, "board", "Target board.") orelse
        error.UnknownBoard;
}

pub fn getArch(board: Board) Arch {
    return switch (board) {
        .qemu_riscv64 => .riscv64,
        .qemu_riscv32 => .riscv32,
        .qemu_arm64 => .arm64,
        .versatilepb_arm => .arm,
        .pc_x86_64 => .x86_64,
        .pc_i386 => .i386,
    };
}

pub fn queryFor(board: Board) std.Target.Query {
    switch (board) {
        .qemu_riscv64 => return .{
            .cpu_arch = .riscv64,
        },
        .pc_x86_64 => return .{
            .cpu_arch = .x86_64,
        },
        else => @panic("Unsupported Board"),
    }
}

pub fn addInstallObjectFile(
    b: *std.Build,
    compile: *std.Build.Step.Compile,
    name: []const u8,
) *std.Build.Step {
    // bin always needed to be computed or else the compilation will do nothing. zig build system bug?
    const bin = compile.getEmittedBin();
    return &b.addInstallFile(bin, b.fmt("bin/{s}.o", .{name})).step;
}

pub fn build(b: *std.Build) void {
    const board = getBoard(b) catch @panic("Unknown Board!");
    var modTargetQuery = queryFor(board);
    var targetQuery = queryFor(board);
    //if (getArch(board) == .x86_64) {
    //    const Features = std.Target.x86.Feature;
    //    targetQuery.cpu_features_sub.addFeature(@intFromEnum(Features.mmx));
    //    targetQuery.cpu_features_sub.addFeature(@intFromEnum(Features.sse));
    //    targetQuery.cpu_features_sub.addFeature(@intFromEnum(Features.sse2));
    //    targetQuery.cpu_features_sub.addFeature(@intFromEnum(Features.avx));
    //    targetQuery.cpu_features_sub.addFeature(@intFromEnum(Features.avx2));
    //    targetQuery.cpu_features_add.addFeature(@intFromEnum(Features.soft_float));
    //}
    modTargetQuery.os_tag = .freestanding;
    modTargetQuery.abi = .none;
    targetQuery.os_tag = .freestanding;
    targetQuery.abi = .none;
    const resolvedTarget = b.resolveTargetQuery(targetQuery);
    const resolvedModTarget = b.resolveTargetQuery(modTargetQuery);
    const optimize = b.standardOptimizeOption(.{});

    const kernel = b.addExecutable(.{
        .name = "kernel",
        .root_source_file = b.path("kernel/main.zig"),
        .optimize = optimize,
        .target = resolvedTarget,
        .linkage = .static,
        .code_model = .large,
        .strip = false,
    });
    if (getArch(board) == .riscv64) {
        kernel.root_module.code_model = .medium;
    }
    const dtbMod = b.addModule("dtb", .{
        .root_source_file = b.path("dtb/dtb.zig"),
        .imports = &.{},
        .target = resolvedTarget,
        .optimize = optimize,
        .red_zone = false,
        .strip = false,
    });
    const halMod = b.addModule("hal", .{
        .root_source_file = b.path("hal/hal.zig"),
        .imports = &.{.{ .name = "dtb", .module = dtbMod }},
        .target = resolvedTarget,
        .optimize = optimize,
        .red_zone = false,
        .strip = false,
    });

    const wrenMod = b.addObject(.{
        .name = "wren",
        .root_source_file = b.path("wren/main.zig"),
        .target = resolvedModTarget,
        .optimize = optimize,
        .code_model = .medium,
        .strip = true,
    });
    wrenMod.addCSourceFiles(.{ .files = &.{
        "wren/wren_compiler.c",
        "wren/wren_core.c",
        "wren/wren_primitive.c",
        "wren/wren_utils.c",
        "wren/wren_value.c",
        "wren/wren_vm.c",
        "wren/wren_opt_meta.c",
        "wren/wren_debug.c",
        "wren/vmstdlib_c.c",
        "wren/tinyprintf.c",
    } });
    wrenMod.entry = std.Build.Step.Compile.Entry.disabled;
    kernel.entry = std.Build.Step.Compile.Entry.disabled;
    kernel.root_module.addImport("dtb", dtbMod);
    kernel.root_module.addImport("hal", halMod);
    kernel.setLinkerScript(b.path(b.fmt("hal/link/{s}.ld", .{@tagName(board)})));
    b.getInstallStep().dependOn(&b.addInstallArtifact(kernel, .{}).step);
    b.getInstallStep().dependOn(addInstallObjectFile(b, wrenMod, "wren"));
}
