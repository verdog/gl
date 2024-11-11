/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn framebufferSizeCallback(_: glfw.Window, width: u32, height: u32) void {
    gl.Viewport(0, 0, @intCast(width), @intCast(height));
}

var first_mouse = true;

fn mouse_callback(_: glfw.Window, xpos: f64, ypos: f64) void {
    if (first_mouse) {
        mouse_last_x = xpos;
        mouse_last_y = ypos;
        first_mouse = false;
    }

    const sensitivity = 0.1;
    const x_offset = sensitivity * (xpos - mouse_last_x);
    const y_offset = sensitivity * (mouse_last_y - ypos); // treating positive y as down
    mouse_last_x = xpos;
    mouse_last_y = ypos;

    yaw += @floatCast(x_offset);
    pitch += @floatCast(y_offset);
    // if camera looks up, we get a "lookAt flip" which rotates the whole scene
    // 180 degrees as we cross over from looking forward to looking backward
    pitch = std.math.clamp(pitch, -89.9, 89.9);

    camera_front = za.Vec3.new(
        @cos(za.toRadians(yaw)) * @cos(za.toRadians(pitch)),
        @sin(za.toRadians(pitch)),
        @sin(za.toRadians(yaw)) * @cos(za.toRadians(pitch)),
    ).norm();
}

fn scroll_callback(_: glfw.Window, xoff: f64, yoff: f64) void {
    _ = xoff;
    fov = std.math.clamp(fov - @as(f32, @floatCast(yoff)), 1, 90);
}

var gl_procs: gl.ProcTable = undefined;

var polygons = false;
var polygons_up = true;

var camera_pos = za.Vec3.new(0, 0, 0);
var camera_front = za.Vec3.new(0, 0, -1);
var camera_up = za.Vec3.new(0, 1, 0);

var pitch: f32 = 0;
var yaw: f32 = -90;

var delta_time: f64 = 0.0;
var last_frame: f64 = 0.0;

var mouse_last_x: f64 = 400;
var mouse_last_y: f64 = 300;

var fov: f32 = 45.0;

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

    const cam_speed: f32 = @floatCast(5 * delta_time);

    if (window.getKey(.w) == .press) {
        camera_pos = camera_pos.add(camera_front.scale(cam_speed));
    }
    if (window.getKey(.s) == .press) {
        camera_pos = camera_pos.sub(camera_front.scale(cam_speed));
    }
    if (window.getKey(.a) == .press) {
        const dir = camera_front.cross(camera_up).norm().scale(cam_speed);
        camera_pos = camera_pos.sub(dir);
    }
    if (window.getKey(.d) == .press) {
        const dir = camera_front.cross(camera_up).norm().scale(cam_speed);
        camera_pos = camera_pos.add(dir);
    }
}

// zig fmt: off
const vertices = [_]f32{
    // x    y      z      u     v
    -0.5 , -0.5 , -0.5 ,  0.0 , 0.0,
     0.5 , -0.5 , -0.5 ,  1.0 , 0.0,
     0.5 ,  0.5 , -0.5 ,  1.0 , 1.0,
     0.5 ,  0.5 , -0.5 ,  1.0 , 1.0,
    -0.5 ,  0.5 , -0.5 ,  0.0 , 1.0,
    -0.5 , -0.5 , -0.5 ,  0.0 , 0.0,

    -0.5 , -0.5 ,  0.5 ,  0.0 , 0.0,
     0.5 , -0.5 ,  0.5 ,  1.0 , 0.0,
     0.5 ,  0.5 ,  0.5 ,  1.0 , 1.0,
     0.5 ,  0.5 ,  0.5 ,  1.0 , 1.0,
    -0.5 ,  0.5 ,  0.5 ,  0.0 , 1.0,
    -0.5 , -0.5 ,  0.5 ,  0.0 , 0.0,

    -0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,
    -0.5 ,  0.5 , -0.5 ,  1.0 , 1.0,
    -0.5 , -0.5 , -0.5 ,  0.0 , 1.0,
    -0.5 , -0.5 , -0.5 ,  0.0 , 1.0,
    -0.5 , -0.5 ,  0.5 ,  0.0 , 0.0,
    -0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,

     0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,
     0.5 ,  0.5 , -0.5 ,  1.0 , 1.0,
     0.5 , -0.5 , -0.5 ,  0.0 , 1.0,
     0.5 , -0.5 , -0.5 ,  0.0 , 1.0,
     0.5 , -0.5 ,  0.5 ,  0.0 , 0.0,
     0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,

    -0.5 , -0.5 , -0.5 ,  0.0 , 1.0,
     0.5 , -0.5 , -0.5 ,  1.0 , 1.0,
     0.5 , -0.5 ,  0.5 ,  1.0 , 0.0,
     0.5 , -0.5 ,  0.5 ,  1.0 , 0.0,
    -0.5 , -0.5 ,  0.5 ,  0.0 , 0.0,
    -0.5 , -0.5 , -0.5 ,  0.0 , 1.0,

    -0.5 ,  0.5 , -0.5 ,  0.0 , 1.0,
     0.5 ,  0.5 , -0.5 ,  1.0 , 1.0,
     0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,
     0.5 ,  0.5 ,  0.5 ,  1.0 , 0.0,
    -0.5 ,  0.5 ,  0.5 ,  0.0 , 0.0,
    -0.5 ,  0.5 , -0.5 ,  0.0 , 1.0,
};
// zig fmt: on

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
        window.setInputModeCursor(.disabled);
        window.setCursorPosCallback(mouse_callback);
        window.setScrollCallback(scroll_callback);

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

    const data2 = stbimg.stbi_load("./src/textures/dogsplusplus_logo.png", &tex_width, &tex_height, &tex_n_channels, 0);
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
    gl.BindVertexArray(vao);

    var vbo: gl.uint = undefined;
    gl.GenBuffers(1, @ptrCast(&vbo));

    {
        gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
        // pos
        gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
        gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), 0);
        gl.EnableVertexAttribArray(0);
        // texcoord
        gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), 3 * @sizeOf(f32));
        gl.EnableVertexAttribArray(1);
    }

    {
        gl.BindBuffer(gl.ARRAY_BUFFER, 0);
        gl.BindVertexArray(0);
    }

    const shader = try Shader.init(@embedFile("vert.glsl"), @embedFile("frag.glsl"));
    shader.activate();
    try shader.set(i32, "tex0", 0);
    try shader.set(i32, "tex1", 1);

    gl.Enable(gl.DEPTH_TEST);

    // Wait for the user to close the window.
    while (!window.shouldClose()) {
        const current_frame = glfw.getTime();
        delta_time = current_frame - last_frame;
        last_frame = current_frame;

        processInput(window);

        gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        const view = za.lookAt(
            camera_pos,
            camera_pos.add(camera_front),
            camera_up,
        );
        // const view = za.Mat4.identity();

        const proj = za.Mat4.perspective(fov, 800.0 / 600.0, 0.1, 100.0);
        // const proj = za.Mat4.identity();

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

        const cube_positions = [_]za.Vec3{
            za.Vec3.new(0.0, 0.0, 0.0),
            za.Vec3.new(2.0, 5.0, -15.0),
            za.Vec3.new(-1.5, -2.2, -2.5),
            za.Vec3.new(-3.8, -2.0, -12.3),
            za.Vec3.new(2.4, -0.4, -3.5),
            za.Vec3.new(-1.7, 3.0, -7.5),
            za.Vec3.new(1.3, -2.0, -2.5),
            za.Vec3.new(1.5, 2.0, -2.5),
            za.Vec3.new(1.5, 0.2, -1.5),
            za.Vec3.new(-1.3, 1.0, -1.5),
        };

        for (cube_positions, 0..cube_positions.len) |pos, i| {
            const model = za.Mat4.fromTranslate(pos)
                .rotate(@as(f32, @floatCast(glfw.getTime() * 50)) + (20.0 * @as(f32, @floatFromInt(i))), za.Vec3.new(1.0, 0.3, 0.5));
            const model_loc = gl.GetUniformLocation(shader.id, "model");
            gl.UniformMatrix4fv(model_loc, 1, gl.FALSE, @ptrCast(&model.data));
            gl.DrawArrays(gl.TRIANGLES, 0, 36);
        }

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
