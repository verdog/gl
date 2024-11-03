const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const glfw_dep = b.dependency("mach-glfw", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("glfw", glfw_dep.module("mach-glfw"));

    // Choose the OpenGL API, version, profile and extensions you want to generate bindings for.
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"3.3",
        .profile = .core,
        .extensions = &.{},
    });
    exe.root_module.addImport("gl", gl_bindings);

    const stb_dep = b.dependency("stb", .{
        .target = target,
        .optimize = optimize,
    });
    const stb = b.addTranslateC(.{
        .root_source_file = stb_dep.path("stb_image.h"),
        .target = target,
        .optimize = optimize,
    });
    exe.addCSourceFile(.{ .file = b.path("src/stb_image_impl.c"), .flags = &.{
        "-O2",
        "-I",
        stb_dep.path(".").getPath3(b, &stb.step).root_dir.path.?,
    } });
    exe.root_module.addImport("stbimg", stb.createModule());

    const za = b.dependency("zalgebra", .{});
    exe.root_module.addImport("za", za.module("zalgebra"));

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addImport("glfw", glfw_dep.module("mach-glfw"));
    exe_unit_tests.root_module.addImport("gl", gl_bindings);
    exe_unit_tests.root_module.addImport("stbimg", stb.createModule());
    exe_unit_tests.root_module.addImport("za", za.module("zalgebra"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);

    const docs_step = b.step("docs", "Emit docs");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = exe.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
}
