// #region Namespace imports
const std = @import("std");
const libs = @import("../../../../libs/libs.zig");
const globals = @import("../../../globals.zig");
const engine = @import("../../../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Entity = @import("../../entity.zig");
const NPCEntityData = @import("npc_entity_data.zig");
const GameWorld = @import("../../../world.zig");
const GameRandom = engine.core.random.GameRandom;
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

pub fn resolve_plan(entity: *Entity, world: *GameWorld, delta_time: f32, rng: *GameRandom) !void {
    var npc = entity.npcData();
    const plan = npc.action_plan orelse return;

    switch (plan.action) {
        .ChangeState => {
            //std.log.info("Entity {d} change its state to {s}", .{ entity.id, @tagName(plan.newState.?) });
            npc.state = plan.newState.?;
            npc.action_plan = null;
            entity.movement_elapsed = 0.0;
            return;
        },
        .ApplyState => {
            //std.log.info("Entity {d} apply its state {s}", .{ entity.id, @tagName(npc.state) });
        },
    }
    const movement_speed: ?f32 = switch (npc.state) {
        .Wandering, .Guarding => entity.normal_speed,
        .Chasing, .Fleeing => entity.max_speed,
        .Idle => null,
    };
    if (movement_speed) |speed| {
        entity.movement_elapsed += delta_time;
        const seconds_per_move = 1.0 / speed;
        if (entity.movement_elapsed < seconds_per_move) return;
        entity.movement_elapsed -= seconds_per_move;
    }

    switch (npc.state) {
        .Idle => {
            if (try rng.nextU64() < 32) {
                npc.action_plan = .{ .action = NPCAction.ChangeState, .newState = NPCState.Wandering };
                return;
            }
        },
        .Wandering => resolveWanderingPlan(entity, npc, plan, world),
        .Chasing => resolveChasingPlan(entity, plan, world),
        //.Guarding => resolveGuardingPlan(soldier, plan, world),
        //.Fleeing => resolveFleeingPlan(soldier, plan, world),
        else => {},
    }
    npc.action_plan = null;
}

fn resolveChasingPlan(entity: *Entity, plan: NPCActionPlan, world: *GameWorld) void {
    std.debug.assert(plan.target != null);
    const target = plan.target.?;
    const isAvailable = !world.isCellOccupied(target);
    if (isAvailable) {
        entity.move(target);
        return;
    }
    const character = world.getCharacter() orelse return;
    if (!target.equal(&character.cell)) {
        return;
    }
    character.health.reduceBy(entity.force);
}

fn resolveWanderingPlan(entity: *Entity, npc: *NPCEntityData, plan: NPCActionPlan, world: *GameWorld) void {
    std.debug.assert(plan.target != null);
    const target = plan.target.?;
    const isAvailable = !world.isCellOccupied(target);
    if (!isAvailable) {
        npc.action_plan = .{ .action = NPCAction.ChangeState, .newState = NPCState.Idle };
        return;
    }
    entity.move(target);
}

pub fn clearPlans(world: *GameWorld) void {
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            if (entity.npcData()) |npc| npc.action_plan = null;
        }
    }
}
