// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
const npc_plans = @import("../entities/npc/generic/npc_plans.zig");
// #endregion

// #region Concrete imports
const Entity = @import("entity.zig");
const GameWorld = @import("../world.zig");
const NPCActionPlan = npc_plans.NPCActionPlan;
const NPCAction = npc_plans.NPCAction;
const NPCState = npc_plans.NPCState;
const NPCEntityData = @import("../entities/npc/generic/npc_entity_data.zig");
const GameRandom = engine.core.random.GameRandom;

// #endregion

pub fn resolve_entities(world: *GameWorld, delta_time: f32, rng: *GameRandom) !void {
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            switch (entity.type) {
                .npc => {
                    try npc_plans.resolve_plan(entity, world, delta_time, rng);
                    //std.log.info("State and plan after resolve : {s} / {any}",.{@tagName(entity.readNpcData().state),entity.readNpcData().action_plan});
                },
                .character => {},
            }
            if (entity.health.isDead()) {
                world.destroyEntity(entity.id);
            }
        }
    }
}
