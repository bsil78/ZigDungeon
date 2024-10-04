const Vector2 = @import("vector.zig").Vector2;
const Rect = @import("Rect.zig").Rect;
const Transform = @This();

position: Vector2(f32) = Vector2(f32).Zero(),
scale: Vector2(f32) = Vector2(f32).One(),
rotation: f32 = 0.0,
parent_transform: ?*Transform = null,

pub fn shift(self: *Transform, offset: Vector2(f32)) void {
    self.position = self.position.add(offset);
}

pub fn xform(self: *const Transform, trans: *const Transform) Transform {
    return .{
        .position = self.position.add(trans.position),
        .scale = self.scale.times(trans.scale),
        .rotation = self.rotation + trans.rotation,
    };
}

pub fn toGlobal(self: *Transform) Transform {
    if (self.parent_transform) |trans| {
        const global_parent_trans = trans.toGlobal();
        return self.xform(&global_parent_trans);
    } else {
        return self.*;
    }
}
