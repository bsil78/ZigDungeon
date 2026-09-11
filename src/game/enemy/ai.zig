// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const engine = @import("../../engine/engine.zig");
// #endregion

// #region Concrete imports
const CellsList = std.ArrayList(Vector2(i16));
const Vector2 = maths.geometry.vectors.Vector2;
const GameWorld = @import("../world/world.zig").GameWorld;
const Enemy = @import("../enemy/enemy.zig").Enemy;
const NPCActionPlan = @import("../enemy/action_plan.zig").NPCActionPlan;
const NPCState = @import("../enemy/action_plan.zig").NPCState;
const NPCAction = @import("../enemy/action_plan.zig").NPCAction;
// #endregion



//algorithm: The update function is called every frame to update the action plans of all enemies in the game world.
// It first checks if the current frame is a multiple of 20, and if not, it returns early to avoid updating the action plans too frequently.
// If it is time to update, it computes the distances from the character's position to all other cells in the game world using a pathfinding algorithm.
// Then, for each enemy, it computes the best action plan based on the distances and updates the enemy's action plan accordingly. 
pub fn update(world: *GameWorld) !void {
    for (world.enemies.items) |*enemy| {
        std.debug.print("Updating {d}\n",.{enemy.entityId});
        enemy.action_plan = try computeActionPlan(enemy,  world);
    }
}

// algorithm: given enemy, we compute the best action plan
fn computeActionPlan(enemy: *Enemy, world: *GameWorld) !?NPCActionPlan
{
   if(enemy.health.hp<=10){
        return .{ 
            .action = NPCAction.ChangeState,
            .newState = NPCState.Fleeing,
            };
    }
    //std.debug.print("Enemy {d} state is : {d}\n",.{enemy.entityId,enemy.state});
    switch(enemy.state){
        .Chasing=> return try chasingPlan(enemy, world),
        .Wandering=> return try wanderingPlan(enemy, world),
        //.Guarging=> return try guardingPlan(enemy, world),
        .Fleeing=> return try fleeingPlan(enemy, world),
        else =>return null
    }

}

// Chase player by finding the best target cell to move towards.
// if the enemy can reach the character's cell (distance is not 0xFF), it will choose corresponding direction.
// Otherwise, it will target a random accessible cell.
fn chasingPlan(enemy: *Enemy, world: *GameWorld) !?NPCActionPlan
{
    try world.populateAccessibleCells(enemy.position.cell);
    const cells = world.accessibleCells.items;
    if (cells.len == 0) return null;

    var best_target: ?Vector2(i16) = null;
    var best_distance: u8 = 0xFF;

    for (cells) |cell| {
        const distances = (try world.getCharacterDistances());

        const x: usize = @intCast(cell.x);
        const y: usize = @intCast(cell.y);
        if (x >= distances[0].len or y >= distances.len) continue;

        
        const cell_distance = distances[y][x];
        if (cell_distance == 0xFF) continue;

        if (best_target == null or cell_distance < best_distance) {
            best_distance = cell_distance;
            best_target = cell;
        }
    }

    if (best_distance > 12) {
        //std.debug.print("Ennemy {d} plan is to change state for Wandering\n",.{enemy.entityId});
        return .{ .action= NPCAction.ChangeState , .newState = NPCState.Wandering };
    }

    if (best_target) |target| {
        //std.debug.print("Best target for {d} is : ({d},{d})\n",.{enemy.entityId, target.x,target.y});
        return .{ .target = target };
    }

    const random_index = try engine.random.index(cells.len);
    return .{ .target = cells[random_index] };

}


fn wanderingPlan(enemy: *Enemy, world: *GameWorld) !?NPCActionPlan
{
    try world.populateAccessibleCells(enemy.position.cell);
    const cells = world.accessibleCells.items;
    if (cells.len == 0) return null;

    var best_distance: u8 = 0xFF;

    for (cells) |cell| {
        const distances = (try world.getCharacterDistances());
        const x: usize = @intCast(cell.x);
        const y: usize = @intCast(cell.y);
        if (x >= distances[0].len or y >= distances.len) continue;
        const cell_distance = distances[y][x];
        if (cell_distance == 0xFF) continue;

        if (cell_distance < best_distance) {
            best_distance = cell_distance;
        }
    }

    if (best_distance<8) {
        //std.debug.print("Ennemy {d} plan is to change state for Chasing\n",.{enemy.entityId});
        return .{ .action= NPCAction.ChangeState , .newState = NPCState.Chasing };
    }

    //std.debug.print("Ennemy {d} will move randomly",.{enemy.entityId});
    const random_index = try engine.random.index(cells.len);
    return .{ .target = cells[random_index] };
}

//fn guardingPlan(_enemy: *Enemy, _world: *GameWorld) !?NPCActionPlan
//{
    // TBD
    //return null;
//}

fn fleeingPlan(enemy: *Enemy, world: *GameWorld) !?NPCActionPlan
{
    try world.populateAccessibleCells(enemy.position.cell);
    const cells = world.accessibleCells.items;
    std.debug.assert(cells.len<5);
    var possible_cells = try CellsList.initCapacity(world.allocator, 4);
    defer possible_cells.deinit(world.allocator);
    for(0..cells.len)|i|{
        if(world.isCellOccupied(cells[i])) continue;
        possible_cells.appendAssumeCapacity(cells[i]);
    }
    if(possible_cells.items.len==0) return null;
    if(possible_cells.items.len==1) return .{ .target = possible_cells.items[0] };
    const random_index = try engine.random.index(possible_cells.items.len);
    return .{ .target = possible_cells.items[random_index] };
}

