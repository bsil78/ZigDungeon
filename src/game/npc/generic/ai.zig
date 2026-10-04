// #region Namespace imports
const std = @import("std");
const maths = @import("../../../libs/maths/maths.zig");
const engine = @import("../../../engine/engine.zig");
const globals = @import("../../globals.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const GameWorld = @import("../../world.zig").GameWorld;
const NPCActionPlan = @import("action_plan.zig").NPCActionPlan;
const NPCState = @import("action_plan.zig").NPCState;
const NPCAction = @import("action_plan.zig").NPCAction;
const WorldCell = @import("../../game_types.zig").WorldCell;
const Entity = @import("../../entity.zig").Entity;
const NPCEntityData = @import("npc_entity_data.zig").NPCEntityData;
// #endregion

// Called each frame, this computes plans for NPCs without pending plans using
// distances from the character. Movement resolution is scheduled per entity.
pub fn update(world: *GameWorld) !void {
    const distances = (try world.getCharacterDistances());
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            const npc = entity.npcData() orelse continue;
            if (npc.action_plan != null) continue;
            if (try computeActionPlan(entity, npc, &distances, world)) |plan| {
                npc.action_plan = plan;
            }
        }
    }
}

fn computeActionPlan(entity: *const Entity, npc: *const NPCEntityData, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld) !?NPCActionPlan {
    if (entity.health.hp <= 10) {
        return .{
            .action = NPCAction.ChangeState,
            .newState = NPCState.Fleeing,
        };
    }
    switch (npc.state) {
        .Chasing => return try chasingPlan(entity, distances, world),
        .Idle, .Wandering => return try wanderingPlan(entity, distances, world),
        //.Guarging=> return try guardingPlan(soldier, distances, world),
        .Fleeing => return try fleeingPlan(entity, world),
        else => return null,
    }
}

// Chase the player by finding the best target cell to move towards.
// If an NPC can reach the character's cell (distance is not 0xFF), choose the corresponding direction.
// Otherwise, it will target a random accessible cell.
fn chasingPlan(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld) !?NPCActionPlan {
    const cells: [4]?WorldCell = try world.getEnemyFreeAccessibleCells(entity.cell, entity.id);
    //std.log.info("accessible cells are : {any}\n", .{cells});

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

    const random_index = try engine.random.index(nbAccessible);
    return .{ .target = cells[random_index] };
}

fn wanderingPlan(entity: *const Entity, distances: *const [globals.WORLD_LEN]u8, world: *const GameWorld) !?NPCActionPlan {
    const cells: [4]?WorldCell = try world.getEnemyFreeAccessibleCells(entity.cell, entity.id);
    //std.log.info("accessible cells are : {any}\n", .{cells});

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
    const random_index = try engine.random.index(nbAccessible);
    const newTarget = cells[random_index];
    return .{ .target = newTarget };
}

//fn guardingPlan(_soldier: *Soldier,distances:*const [globals.WORLD_LEN]u8,, _world: *GameWorld) !?NPCActionPlan
//{
// TBD
//return null;
//}

fn fleeingPlan(entity: *const Entity, world: *const GameWorld) !?NPCActionPlan {
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
    const random_index = try engine.random.index(nbAccessible);
    const newTarget = cells[random_index];
    return .{ .target = newTarget };
}
