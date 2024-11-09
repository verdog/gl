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
    // positions          // colors           // texture coords
    0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0, // top right
    0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, // bottom right
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, // bottom left
    -0.5, 0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, // top left
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

    stbimg.stbi_set_flip_vertically_on_load(1);

    // Load texture
    var tex_width: i32 = undefined;
    var tex_height: i32 = undefined;
    var tex_n_channels: i32 = undefined;
    const data = stbimg.stbi_load("./src/textures/container.jpg", &tex_width, &tex_height, &tex_n_channels, 0);
    if (data == null) return error.FailedToLoadTexture;

    var tex0_id: gl.uint = undefined;
    gl.GenTextures(1, @ptrCast(&tex0_id));
    gl.BindTexture(gl.TEXTURE_2D, tex0_id);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, tex_width, tex_height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
    gl.GenerateMipmap(gl.TEXTURE_2D);
    stbimg.stbi_image_free(data);

    const data2 = stbimg.stbi_load("./src/textures/awesomeface.png", &tex_width, &tex_height, &tex_n_channels, 0);
    if (data2 == null) return error.FailedToLoadTexture;
    var tex1_id: gl.uint = undefined;
    gl.GenTextures(1, @ptrCast(&tex1_id));
    gl.BindTexture(gl.TEXTURE_2D, tex1_id);
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, tex_width, tex_height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data2);
    gl.GenerateMipmap(gl.TEXTURE_2D);
    stbimg.stbi_image_free(data2);

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

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.EnableVertexAttribArray(1);
    gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
    gl.EnableVertexAttribArray(2);

    gl.BindBuffer(gl.ARRAY_BUFFER, 0);
    gl.BindVertexArray(0);

    const shader = try Shader.init(@embedFile("vert.glsl"), @embedFile("frag.glsl"));
    shader.activate();
    try shader.set(i32, "tex0", 0);
    try shader.set(i32, "tex1", 1);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        processInput(window);

        gl.Clear(gl.COLOR_BUFFER_BIT);

        const model = za.Mat4.fromRotation(-55, za.Vec3.new(1.0, 0.0, 0.0));
        // const model = za.Mat4.identity();

        const view = za.Mat4.fromTranslate(za.Vec3.new(0, 0, -3));
        // const view = za.Mat4.identity();

        const proj = za.Mat4.perspective(45, 800.0 / 600.0, 0.1, 100.0);
        // const proj = za.Mat4.identity();

        const model_loc = gl.GetUniformLocation(shader.id, "model");
        gl.UniformMatrix4fv(model_loc, 1, gl.FALSE, @ptrCast(&model.data));

        const view_loc = gl.GetUniformLocation(shader.id, "view");
        gl.UniformMatrix4fv(view_loc, 1, gl.FALSE, @ptrCast(&view.data));

        const proj_loc = gl.GetUniformLocation(shader.id, "proj");
        gl.UniformMatrix4fv(proj_loc, 1, gl.FALSE, @ptrCast(&proj.data));

        shader.activate();
        gl.ActiveTexture(gl.TEXTURE0);
        gl.BindTexture(gl.TEXTURE_2D, tex0_id);
        gl.ActiveTexture(gl.TEXTURE1);
        gl.BindTexture(gl.TEXTURE_2D, tex1_id);
        gl.BindVertexArray(vao);
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);

        window.swapBuffers();
        glfw.pollEvents();
    }
}

const Shader = @import("Shader.zig");

const gl = @import("gl");
const za = @import("za");
const glfw = @import("glfw");
const std = @import("std");
const stbimg = @import("stbimg");
