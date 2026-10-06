// #region Namespace imports
const npc_plans = @import("npc_plans.zig");
const ai = @import("ai.zig");
// #endregion

state: npc_plans.NPCState = .Idle,
action_plan: ?npc_plans.NPCActionPlan = null,
normal_speed: f32 = 1.0,
max_speed: f32 = 3.0,
movement_elapsed: f32 = 0.0,
brain: ai.Brain = ai.enemyBrain(),
