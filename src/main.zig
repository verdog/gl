/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn framebufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

var gl_procs: gl.ProcTable = undefined;

var polygons = false;
var polygons_up = true;

fn processInput(window: glfw.Window) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }

    if (window.getKey(.z) == .press) {
        if (polygons_up) {
            polygons = !polygons;
            polygons_up = false;
            gl.PolygonMode(gl.FRONT_AND_BACK, if (polygons) gl.LINE else gl.FILL);
        }
    } else {
        polygons_up = true;
    }
}

const vertices = [_]f32{
    // positions    // colors
    0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // bottom right
    -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // bottom left
    0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top
};

const indices = [_]u32{
    0, 1, 2,
};

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = blk: {
        var hints = glfw.Window.Hints{};
        hints.context_version_major = gl.info.version_major;
        hints.context_version_minor = gl.info.version_minor;
        hints.opengl_profile = switch (gl.info.api) {
            .gl => .opengl_core_profile,
            else => comptime unreachable,
        };

        var window = glfw.Window.create(800, 600, "gl", null, null, hints) orelse {
            std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            std.process.exit(1);
        };

        window.setFramebufferSizeCallback(framebufferSizeCallback);

        break :blk window;
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);
    defer glfw.makeContextCurrent(null);

    if (!gl_procs.init(glfw.getProcAddress)) {
        std.log.err("failed to init gl procs: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }

    gl.makeProcTableCurrent(&gl_procs);
    defer gl.makeProcTableCurrent(null);

    gl.ClearColor(0.2, 0, 0.4, 1);
    var attribs: gl.uint = undefined;
    gl.GetIntegerv(gl.MAX_VERTEX_ATTRIBS, @ptrCast(&attribs));
    std.log.info("max vert attribs: {d}\n", .{attribs});
    gl.Viewport(0, 0, 800, 600);

    var vao: gl.uint = undefined;
    gl.GenVertexArrays(1, @ptrCast(&vao));
    var vbo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));
    var ebo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&ebo));

    gl.BindVertexArray(vao);

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);

    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.EnableVertexAttribArray(1);

    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);

    const shader = try Shader.init(@embedFile("vert.glsl"), @embedFile("frag.glsl"));

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        processInput(window);

        gl.Clear(gl.COLOR_BUFFER_BIT);

        shader.activate();
        gl.BindVertexArray(vao);
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const Shader = @import("Shader.zig");

const gl = @import("gl");
const glfw = @import("glfw");
const std = @import("std");
