// #region Namespace imports
const maths = @import("../../libs/maths/maths.zig");
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

// Complex action plan made of a NPCAction (ApplyingState by default), an optional new NPCState, and an optional target
// Consists of a target cell that the enemy will move towards in the next game update.
pub const NPCActionPlan = struct {
    action: NPCAction=NPCAction.ApplyState,
    newState: ?NPCState = null,
    target: ?Vector2(i16) = null,
};

