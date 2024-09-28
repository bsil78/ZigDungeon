const Vector2 = @import("vector.zig").Vector2;
const Rect = @import("Rect.zig").Rect;
const Transform = @This();

position: Vector2(f32) = Vector2(f32).Zero(),
scale: Vector2(f32) = Vector2(f32).One(),
rotation: f32 = 0.0,

pub fn xform(self: *const Transform, trans: *const Transform) Transform {
    return Transform{
        .position = self.position.add(trans.position),
        .scale = self.scale.times(trans.scale),
        .rotation = self.rotation + trans.rotation,
    };
}
