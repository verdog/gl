id: gl.uint = undefined,

pub fn activate(self: Shader) void {
    gl.UseProgram(self.id);
}

pub fn set(self: Shader, T: type, name: [*:0]const u8, value: T) !void {
    const loc = gl.GetUniformLocation(self.id, name);
    if (loc == -1) return error.UniformNotFound;

    switch (T) {
        i32 => {
            gl.Uniform1i(loc, value);
        },
        f32 => {
            gl.Uniform1f(loc, value);
        },
        bool => {
            gl.Uniform1i(loc, value);
        },
        else => {
            comptime unreachable;
        },
    }
}

pub fn init(vertex_src: []const u8, fragment_src: []const u8) !Shader {
    var result = Shader{};

    const vert_shader = blk: {
        const vert_id = gl.CreateShader(gl.VERTEX_SHADER);
        gl.ShaderSource(vert_id, 1, @ptrCast(&vertex_src), null);
        gl.CompileShader(vert_id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetShaderiv(vert_id, gl.COMPILE_STATUS, &success);
            if (success == 0) {
                gl.GetShaderInfoLog(vert_id, info.len, null, &info);
                std.log.err("vertext shader compilation failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                return error.ShaderCompileError;
            }
        }

        break :blk vert_id;
    };
    defer gl.DeleteShader(vert_shader);

    const frag_shader = blk: {
        const frag_id = gl.CreateShader(gl.FRAGMENT_SHADER);
        gl.ShaderSource(frag_id, 1, @ptrCast(&fragment_src), null);
        gl.CompileShader(frag_id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetShaderiv(frag_id, gl.COMPILE_STATUS, &success);
            if (success == 0) {
                gl.GetShaderInfoLog(frag_id, info.len, null, &info);
                std.log.err("fragment shader compilation failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                return error.SharderCompileError;
            }
        }

        break :blk frag_id;
    };
    defer gl.DeleteShader(frag_shader);

    result.id = blk: {
        const prog_id = gl.CreateProgram();
        gl.AttachShader(prog_id, vert_shader);
        gl.AttachShader(prog_id, frag_shader);
        gl.LinkProgram(prog_id);
        {
            var success: gl.int = undefined;
            var info: [512]u8 = undefined;
            gl.GetProgramiv(prog_id, gl.LINK_STATUS, &success);
            if (success == 0) {
                gl.GetProgramInfoLog(prog_id, info.len, null, &info);
                std.log.err("shader linking failed: {s}\n", .{std.mem.sliceTo(&info, '\x00')});
                return error.ShaderLinkError;
            }
        }

        break :blk prog_id;
    };

    return result;
}

const Shader = @This();

const gl = @import("gl");

const std = @import("std");
