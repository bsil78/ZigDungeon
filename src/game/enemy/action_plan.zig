// #region Namespace imports
const maths = @import("../../libs/maths/maths.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
// #endregion


// Consists of a target cell that the enemy will move towards in the next game update.
pub const ActionPlan = struct {
    target: Vector2(i16),
};
