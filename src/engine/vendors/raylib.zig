const maths = @import("../../libs/maths/maths.zig");
const gfx = @import("../../libs/gfx/gfx.zig");

pub const raylib = @import("../../libs/vendors/raylib.zig").raylib;

pub fn ToRaylib(comptime T: type) type {
    
    return struct {

        pub fn Vector2(vec: *const maths.geometry.vectors.Vector2(T)) raylib.Vector2 {
            const v = vec.toFloatV(f32);
            return raylib.Vector2{ .x = v.x, .y = v.y };
        }

        pub fn Rectangle(rect: *const maths.geometry.shapes.Rect(T)) raylib.Rectangle {
            return raylib.Rectangle{
                .x = rect.x,
                .y = rect.y,
                .width = rect.w,
                .height = rect.h,
            };
        }

        pub fn Color(col: *const gfx.Color) raylib.Color {
            if(T != u8) @compileError("ToRaylib.Color only accepts gfx.Color with u8 components"); 
            return raylib.Color{ .r = col.r, .g = col.g, .b = col.b, .a = col.a };
        }
    };
}
