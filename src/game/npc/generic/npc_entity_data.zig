// #region Namespace imports
const action_plan = @import("action_plan.zig");
// #endregion

pub const NPCEntityData = struct {
    state: action_plan.NPCState = .Idle,
    action_plan: ?action_plan.NPCActionPlan = null,
    normal_speed: f32 = 1.0,
    max_speed: f32 = 3.0,
    movement_elapsed: f32 = 0.0,
};
