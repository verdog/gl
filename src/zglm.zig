const glm = @import("glm");
const std = @import("std");

pub const Vec3 = struct {
    pub fn init0() Vec3 {
        return .{
            .vec3 = .{ 0, 0, 0 },
        };
    }

    pub fn init3(x: f32, y: f32, z: f32) Vec3 {
        return .{
            .vec3 = .{ x, y, z },
        };
    }

    vec3: glm.vec3 align(16),
};

pub const Vec4 = struct {
    pub fn init0() Vec4 {
        return .{
            .vec4 = .{ 0, 0, 0, 0 },
        };
    }

    pub fn init4(_x: f32, _y: f32, _z: f32, _w: f32) Vec4 {
        return .{
            .vec4 = .{ _x, _y, _z, _w },
        };
    }

    pub fn x(self: Vec4) f32 {
        return self.vec4[0];
    }
    pub fn y(self: Vec4) f32 {
        return self.vec4[1];
    }
    pub fn z(self: Vec4) f32 {
        return self.vec4[2];
    }
    pub fn w(self: Vec4) f32 {
        return self.vec4[3];
    }

    vec4: glm.vec4 align(16),
};

pub const Mat4 = struct {
    pub fn init() Mat4 {
        var r = Mat4{
            .mat4 = undefined,
        };
        glm.glmc_mat4_identity(&r.mat4);
        return r;
    }

    pub fn translateBy(self: *Mat4, vec3: Vec3) void {
        glm.glmc_translate(&self.mat4, @constCast(&vec3.vec3));
    }

    pub fn applyTo(self: Mat4, to: anytype) @TypeOf(to) {
        const T = @TypeOf(to);
        var result = T.init0();

        switch (T) {
            (Vec4) => {
                glm.glmc_mat4_mulv(@constCast(&self.mat4), @constCast(&to.vec4), &result.vec4);
                return result;
            },
            else => {
                @compileError("Unsupported applyTo");
            },
        }
    }

    mat4: glm.mat4 align(32),
};

pub fn mat4_mul(lhs: Mat4, rhs: Mat4) Mat4 {
    var result = Mat4.init();
    glm.glmc_mat4_mul(@constCast(&lhs.mat4), @constCast(&rhs.mat4), &result.mat4);
    return result;
}
