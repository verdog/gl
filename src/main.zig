/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn framebufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

var gl_procs: gl.ProcTable = undefined;

fn processInput(window: glfw.Window) void {
    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
    }
}

const vertices = [_]f32{
    // first triangle
    0.5, 0.5, 0.0, // top right
    0.5, -0.5, 0.0, // bottom right
    -0.5, -0.5, 0.0, // bottom left
    -0.5, 0.5, 0.0, // top left
};

const indices = [_]u32{
    0, 1, 3,
    1, 2, 3,
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

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);

    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);

    const vert_shader = blk: {
        const id = gl.CreateShader(gl.VERTEX_SHADER);
        const src = @embedFile("vert.glsl");
        gl.ShaderSource(id, 1, @ptrCast(&src), null);
        gl.CompileShader(id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetShaderiv(id, gl.COMPILE_STATUS, &success);
            if (success == 0) {
                gl.GetShaderInfoLog(id, info.len, null, &info);
                std.log.err("shader compilation failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                std.process.exit(1);
            }
        }

        break :blk id;
    };
    defer gl.DeleteShader(vert_shader);

    const frag_shader = blk: {
        const id = gl.CreateShader(gl.FRAGMENT_SHADER);
        const src = @embedFile("frag.glsl");
        gl.ShaderSource(id, 1, @ptrCast(&src), null);
        gl.CompileShader(id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetShaderiv(id, gl.COMPILE_STATUS, &success);
            if (success == 0) {
                gl.GetShaderInfoLog(id, info.len, null, &info);
                std.log.err("shader compilation failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                std.process.exit(1);
            }
        }

        break :blk id;
    };
    defer gl.DeleteShader(frag_shader);

    const program = blk: {
        const id = gl.CreateProgram();
        gl.AttachShader(id, vert_shader);
        gl.AttachShader(id, frag_shader);
        gl.LinkProgram(id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetProgramiv(id, gl.LINK_STATUS, &success);
            if (success == 0) {
                gl.GetProgramInfoLog(id, info.len, null, &info);
                std.log.err("shader linking failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                std.process.exit(1);
            }
        }

        break :blk id;
    };

    // gl.PolygonMode(gl.FRONT_AND_BACK, gl.LINE);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        processInput(window);

        gl.Clear(gl.COLOR_BUFFER_BIT);

        gl.UseProgram(program);
        gl.BindVertexArray(vao);
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const std = @import("std");
const gl = @import("gl");
const glfw = @import("glfw");
