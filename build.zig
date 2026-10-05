// #region Namespace imports
const std = @import("std");
const builtin = @import("builtin");
// #endregion

pub fn build(b: *std.Build) void {
    if (b.option(bool, "patch-raylib", "Apply the local Raylib build patch") orelse false) {
        const patch_cmd = b.addSystemCommand(&.{
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
        });
        patch_cmd.addFileArg(b.path("patch-raylib.ps1"));
        b.getInstallStep().dependOn(&patch_cmd.step);
        return;
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = createExecutable(b, target, optimize);
    linkRaylib(b, exe, target, optimize);
    installAndRun(b, exe);
    addUnitTests(b, target, optimize);
}

fn createExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "ZigDungeon",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
        .max_rss = 4096 * 1024 * 1024,
    });

    const strip = b.option(
        bool,
        "strip",
        "Strip debug info to reduce binary size, defaults to false",
    ) orelse false;
    exe.root_module.strip = strip;

    return exe;
}

fn linkRaylib(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const raylib_optimize = b.option(
        std.builtin.OptimizeMode,
        "raylib-optimize",
        "Prioritize performance, safety, or binary size (-O flag), defaults to value of optimize option",
    ) orelse optimize;

    const raylib_dep = b.dependency("raylib", .{
        .target = target,
        .optimize = raylib_optimize,
    });

    exe.root_module.linkLibrary(raylib_dep.artifact("raylib"));
}

fn installAndRun(b: *std.Build, exe: *std.Build.Step.Compile) void {
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addUnitTests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const test_module = createTestModule(b, target, optimize);
    const unit_tests = b.addTest(.{
        .root_module = test_module,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const success_message_command: []const []const u8 = if (builtin.os.tag == .windows)
        &.{ "cmd", "/C", "echo" }
    else
        &.{"echo"};
    const success_message = b.addSystemCommand(success_message_command ++ .{"All tests passed."});
    success_message.step.dependOn(&run_unit_tests.step);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&success_message.step);
}

fn createTestModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const test_module = b.createModule(.{
        .root_source_file = b.path("tests/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    test_module.addImport("production_random", b.createModule(.{
        .root_source_file = b.path("src/engine/core/random.zig"),
        .target = target,
        .optimize = optimize,
    }));

    test_module.addImport("production_color", b.createModule(.{
        .root_source_file = b.path("src/libs/gfx/color.zig"),
        .target = target,
        .optimize = optimize,
    }));

    test_module.addImport("production_geometry", b.createModule(.{
        .root_source_file = b.path("src/libs/maths/geometry/geometry.zig"),
        .target = target,
        .optimize = optimize,
    }));

    test_module.addImport("production_sparse_dense_set", b.createModule(.{
        .root_source_file = b.path("src/libs/datastructs/sparse_dense_set.zig"),
        .target = target,
        .optimize = optimize,
    }));

    return test_module;
}
