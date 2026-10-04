// #region Namespace imports
const libs = @import("../../../libs/libs.zig");
// #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
const TypesHelper = libs.utils.TypesHelper;
// #endregion

pub const Transform = @This();

position: Vector2(f32) = Vector2(f32).Zero(),
scale: Vector2(f32) = Vector2(f32).One(),
rotation: f32 = 0.0,
pivot: Vector2(f32) = Vector2(f32).Zero(),

pub fn shift(self: *Transform, offset: Vector2(f32)) void {
    self.position = self.position.add(offset);
}

pub fn xform(self: *const Transform, trans: Transform) Transform {
    return .{
        .position = self.position.add(trans.position),
        .scale = self.scale.times(trans.scale),
        .rotation = self.rotation + trans.rotation,
    };
}
