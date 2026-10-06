// #region Namespace imports
const std = @import("std");
const libs = @import("../../../../libs/libs.zig");
const engine = @import("../../../../engine/engine.zig");
const globals = @import("../../../globals.zig");
const npc_plans = @import("npc_plans.zig");
// #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
const GameWorld = @import("../../../world.zig");
const NPCActionPlan = npc_plans.NPCActionPlan;
const NPCState = npc_plans.NPCState;
const NPCAction = npc_plans.NPCAction;
const WorldCell = @import("../../../game_types.zig").WorldCell;
const Entity = @import("../../entity.zig");
const NPCEntityData = @import("npc_entity_data.zig");
const GameRandom = @import("../../../../engine/engine.zig").core.random.GameRandom;
// #endregion

const AI = @This();
pub const Error = error{BrainMalfunction};
pub const Brain = struct {
    computeActionPlan: *const fn (*const Entity, *const [globals.WORLD_LEN]u8, *const GameWorld, *GameRandom) AI.Error!?NPCActionPlan,
};

// Called each frame, this computes plans for NPCs without pending plans using
// distances from the character. Movement resolution is scheduled per entity.
pub fn update(world: *GameWorld, rng: *GameRandom) !void {
    const distances = (try world.getCharacterDistances());
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            switch (entity.type) {
                .character => continue,
                .npc => {
                    const npc = entity.npcData();
                    //std.log.info("updating plan of entity {d} in state {s}\n", .{ entity.id, @tagName(npc.state) });
                    if (npc.action_plan != null) continue;
                    if (try npc.brain.computeActionPlan(entity, &distances, world, rng)) |plan| {
                        npc.action_plan = plan;
                    }
                    //std.log.info("affected plan {any} to entity {d}\n", .{ entity.readNpcData().action_plan, entity.id });
                },
            }
        }
    }
}

pub fn enemyBrain() Brain {
    return Brain{ .computeActionPlan = struct {
        fn think(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld, rng: *GameRandom) AI.Error!?NPCActionPlan {
            const plan = computeActionPlan(entity, distances, world, rng) catch |err| return {
                std.log.err("{any}", .{err});
                return AI.Error.BrainMalfunction;
            };
            return plan;
        }
    }.think };
}

fn computeActionPlan(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld, rng: *GameRandom) !?NPCActionPlan {
    const npc = entity.readNpcData();
    if (entity.health.hp <= (entity.health.max_hp / 5)) {
        return .{
            .action = NPCAction.ChangeState,
            .newState = NPCState.Fleeing,
        };
    }
    switch (npc.state) {
        .Chasing => return try chasingPlan(entity, distances, world, rng),
        .Idle, .Wandering => return try wanderingPlan(entity, distances, world, rng),
        //.Guarging=> return try guardingPlan(soldier, distances, world),
        .Fleeing => return try fleeingPlan(entity, world, rng),
        else => return null,
    }
}

// Chase the player by finding the best target cell to move towards.
// If an NPC can reach the character's cell (distance is not 0xFF), choose the corresponding direction.
// Otherwise, it will target a random accessible cell.
fn chasingPlan(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld, rng: *GameRandom) !?NPCActionPlan {
    const cells: [4]?WorldCell = try world.getEnemyFreeAccessibleCells(entity.cell, entity.id);

    var best_target: ?WorldCell = null;
    var best_distance: u8 = 0xFF;
    var nbAccessible: u3 = 0;

    for (cells) |aCell| {
        if (aCell) |cell| {
            nbAccessible = nbAccessible + 1;
            const x: usize = @intCast(cell.x);
            const y: usize = @intCast(cell.y);

            const cell_distance = distances[y * globals.WORLD_SIZE.x + x];
            if (cell_distance == 0xFF) continue;

            if (best_target == null or cell_distance < best_distance) {
                best_distance = cell_distance;
                best_target = cell;
            }
        } else {
            break;
        }
    }

    if (nbAccessible < 1) {
        return NPCActionPlan{ .action = NPCAction.ChangeState, .newState = NPCState.Idle };
    }

    if (best_distance > 12) {
        return .{ .action = NPCAction.ChangeState, .newState = NPCState.Wandering };
    }

    if (best_target) |target| {
        return .{ .target = target };
    }

    if (nbAccessible == 1) {
        return .{ .target = cells[0] };
    }
    const random_index = try rng.index(nbAccessible);
    return .{ .target = cells[random_index] };
}

fn wanderingPlan(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld, rng: *GameRandom) !?NPCActionPlan {
    const cells: [4]?WorldCell = try world.getEnemyFreeAccessibleCells(entity.cell, entity.id);
    //std.log.info("entity {d} try wandering plan\n", .{entity.id});
    //std.log.debug("accessible cells are : {any}\n", .{cells});

    var best_distance: u8 = 0xFF;
    var nbAccessible: u3 = 0;

    for (cells) |aCell| {
        if (aCell) |cell| {
            nbAccessible = nbAccessible + 1;
            const x: usize = @intCast(cell.x);
            const y: usize = @intCast(cell.y);

            const cell_distance = distances[y * globals.WORLD_SIZE.x + x];
            if (cell_distance == 0xFF) continue;

            if (cell_distance < best_distance) {
                best_distance = cell_distance;
            }
        } else {
            break;
        }
    }

    if (nbAccessible < 1) {
        return NPCActionPlan{ .action = NPCAction.ChangeState, .newState = NPCState.Idle };
    }

    if (best_distance < 8) {
        return .{ .action = NPCAction.ChangeState, .newState = NPCState.Chasing };
    }

    if (nbAccessible == 1) {
        return .{ .target = cells[0] };
    }
    const random_index = try rng.index(nbAccessible);
    const newTarget = cells[random_index];
    return .{ .target = newTarget };
}

//fn guardingPlan(_soldier: *Soldier,distances:*const [globals.WORLD_LEN]u8,, _world: *GameWorld) !?NPCActionPlan
//{
// TBD
//return null;
//}

fn fleeingPlan(entity: *const Entity, world: *const GameWorld, rng: *GameRandom) !?NPCActionPlan {
    const cells: [4]?WorldCell = try world.getAccessibleCells(entity.cell);
    var nbAccessible: u3 = 0;
    for (0..cells.len) |i| {
        if (cells[i]) |cell| {
            if (world.isCellOccupied(cell)) continue;
            nbAccessible = nbAccessible + 1;
        } else {
            break;
        }
    }
    if (nbAccessible == 0) return null;
    if (nbAccessible == 1) return .{ .target = cells[0] };
    const random_index = try rng.index(nbAccessible);
    const newTarget = cells[random_index];
    return .{ .target = newTarget };
}
