// #region Namespace imports
const std = @import("std");
const engine = @import("../../../engine/engine.zig");
// #endregion

// #region Concrete imports
const GameWorld = @import("../../world.zig").GameWorld;
const NPCActionPlan = @import("action_plan.zig").NPCActionPlan;
const NPCAction = @import("action_plan.zig").NPCAction;
const NPCState = @import("action_plan.zig").NPCState;
const Entity = @import("../../entity.zig").Entity;
const NPCEntityData = @import("npc_entity_data.zig").NPCEntityData;
// #endregion

pub fn resolve(world: *GameWorld, delta_seconds: f32) !void {
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            const npc = entity.npcData() orelse continue;
            try resolveNPCPlan(entity, npc, delta_seconds, world);
            if (entity.health.isDead()) {
                _ = world.destroyEntity(entity.id);
            }
        }
    }
}

fn resolveNPCPlan(entity: *Entity, npc: *NPCEntityData, delta_seconds: f32, world: *GameWorld) !void {
    const plan = npc.action_plan orelse return;

    switch (plan.action) {
        .ChangeState => {
            npc.state = plan.newState.?;
            npc.action_plan = null;
            entity.movement_elapsed = 0.0;
            return;
        },
        .ApplyState => {},
    }
    const movement_speed: ?f32 = switch (npc.state) {
        .Wandering, .Guarding => entity.normal_speed,
        .Chasing, .Fleeing => entity.max_speed,
        .Idle => null,
    };
    if (movement_speed) |speed| {
        if (!std.math.isFinite(speed) or speed <= 0.0 or
            !std.math.isFinite(entity.normal_speed) or entity.normal_speed <= 0.0 or
            !std.math.isFinite(entity.max_speed) or entity.max_speed < entity.normal_speed)
        {
            return error.InvalidMovementSpeed;
        }
        if (!std.math.isFinite(delta_seconds) or delta_seconds < 0.0) {
            return error.InvalidDeltaTime;
        }

        entity.movement_elapsed += delta_seconds;
        const seconds_per_move = 1.0 / speed;
        if (entity.movement_elapsed < seconds_per_move) return;
        entity.movement_elapsed -= seconds_per_move;
    }

    switch (npc.state) {
        .Idle => {
            if (try engine.random.nextU64() < 32) {
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
