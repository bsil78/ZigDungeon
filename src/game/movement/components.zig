// #region Namespace imports
const maths = @import("../../libs/maths/maths.zig");
const globals = @import("../globals.zig");
// #endregion

// #region Concrete imports
const Transform = maths.geometry.Transform;
const Vector2 = maths.geometry.vectors.Vector2;
// #endregion

pub const Position = struct {
    cell: Vector2(i16),
};

pub const LocalTransform = struct {
    local: Transform,
};

pub const WorldTransform = struct {
    world: Transform,
};

pub fn makeTransform(cell: Vector2(i16)) Transform {
    const position = cell.times(globals.tile_size);
    return .{ .position = Vector2(f32).init(@floatFromInt(position.x), @floatFromInt(position.y)) };
}
