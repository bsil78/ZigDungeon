// #region Namespace imports
const maths = @import("../../libs/maths/maths.zig");
const engine = @import("../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const pathfinding = maths.algorithms.pathfinding;
const GameWorld = @import("../world/world.zig").GameWorld;
const Enemy = @import("../enemy/enemy.zig").Enemy;
const ActionPlan = @import("../enemy/action_plan.zig").ActionPlan;
// #endregion



//algorithm: The update function is called every frame to update the action plans of all enemies in the game world.
// It first checks if the current frame is a multiple of 20, and if not, it returns early to avoid updating the action plans too frequently.
// If it is time to update, it computes the distances from the character's position to all other cells in the game world using a pathfinding algorithm.
// Then, for each enemy, it computes the best action plan based on the distances and updates the enemy's action plan accordingly. 
pub fn update(world: *GameWorld) !void {
    if (engine.frames_counter % 20 != 0) return;

    const distances = try pathfinding.breadthFirstDistances(
        world.allocator,
        world.character.?.position.cell,
        @intCast(world.tilemap.grid_size.x),
        @intCast(world.tilemap.grid_size.y),
        @ptrCast(world),
        isCellWalkable,
    );
    defer {
        for (distances) |row| world.allocator.free(row);
        world.allocator.free(distances);
    }

    for (world.enemies.items) |*enemy| {
        enemy.action_plan = try computeActionPlan(enemy, distances, world);
    }
}

// algorithm: For each enemy, we compute the action plan by finding the best target cell to move towards.
// if the enemy can reach the character's cell (distance is not 0xFF), it will choose corresponding direction.
// Otherwise, it will target a random accessible cell.
fn computeActionPlan(enemy: *Enemy, distances: [][]u8, world: *GameWorld) !?ActionPlan {
    try world.populateAccessibleCells(enemy.position.cell);
    const cells = world.work_buffer.items;
    if (cells.len == 0) return null;

    var best_target: ?Vector2(i16) = null;
    var best_distance: u8 = 0xFF;

    for (cells) |cell| {
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

    if (best_target) |target| {
        return .{ .target = target };
    }

    const random_index = try engine.random.index(cells.len);
    return .{ .target = cells[random_index] };
}

// interface fonction for BFS algorithm
fn isCellWalkable(context: *anyopaque, cell: Vector2(i16)) bool {
    const world: *GameWorld = @ptrCast(@alignCast(context));
    return world.isCellWalkable(cell) catch false;
}
