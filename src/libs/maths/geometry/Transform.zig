// #region Namespace imports
const vector = @import("vector.zig");
// #endregion

// #region Concrete imports
const Vector2 = vector.Vector2;
// #endregion
const Transform = @This();

position: Vector2(f32) = Vector2(f32).Zero(),
scale: Vector2(f32) = Vector2(f32).One(),
rotation: f32 = 0.0,

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

pub fn toGlobal(self: *const Transform) Transform {
    return self.*;
}
