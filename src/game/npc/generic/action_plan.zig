// #region Namespace imports
const maths = @import("../../../libs/maths/maths.zig");
const globals = @import("../../globals.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
// #endregion

// All NPC possible actions
pub const NPCAction = enum(u1) {
    ChangeState = 0,
    ApplyState = 1,
};

// All NPC possible states
pub const NPCState = enum(u3) {
    Idle = 0,
    Wandering = 1,
    Guarding = 2,
    Chasing = 3,
    Fleeing = 4,
};

// A plan may request a state change or provide an optional target cell for an
// NPC action.
pub const NPCActionPlan = struct {
    action: NPCAction = NPCAction.ApplyState,
    newState: ?NPCState = null,
    target: ?@TypeOf(globals.WORLD_SIZE) = null,
};
