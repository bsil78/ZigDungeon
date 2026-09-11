const std = @import("std");
const maths = @import("../maths.zig");

const Vector2 = maths.geometry.vectors.Vector2;

pub const IsWalkableFn = *const fn (context: *anyopaque, cell: Vector2(i16)) bool;


// Computes the breadth-first distances from the target cell to all other cells in the grid.
// It returns a 2D array of distances, where each cell contains the distance to the target cell.
// Cells that are not reachable from the target cell will have a distance of 0xFF.
// The function uses a queue to perform a breadth-first search, starting from the target cell and exploring its neighbors.
// The is_walkable function is used to determine if a cell can be traversed or not ;
// it takes a context pointer and a cell position as arguments and returns a boolean indicating whether the cell is walkable.
// IsWalkableFn (interface) would get the form : 
// fn isCellWalkable(context: *anyopaque, cell: Vector2(i16)) bool {
//   const world: *GameWorld = @ptrCast(@alignCast(context));
//   return world.isCellWalkable(cell) catch false;
// } 
pub fn breadthFirstDistances(
    allocator: std.mem.Allocator,
    target: Vector2(i16),
    width: usize,
    height: usize,
    context: *anyopaque,
    is_walkable: IsWalkableFn,
) ![][]u8 {
    const distances = try allocator.alloc([]u8, height);
    errdefer {
        std.debug.print("Error with distances",.{});
        for (distances) |row| allocator.free(row);
        allocator.free(distances);
    }

    for (distances) |*row| {
        row.* = try allocator.alloc(u8, width);
        @memset(row.*, 0xFF);
    }

    var queue = try std.ArrayList(Vector2(i16)).initCapacity(allocator, width * height);
    defer queue.deinit(allocator);

    queue.appendAssumeCapacity(target);
    distances[@intCast(target.y)][@intCast(target.x)] = 0;

    var head: usize = 0;
    while (head < queue.items.len) {
        const current = queue.items[head];
        head += 1;
        const current_distance = distances[@intCast(current.y)][@intCast(current.x)];
        const next_distance: u8 = current_distance + 1;

        for (Vector2(i16).cardinalDirections()) |direction| {
            const next = current.add(&direction);
            if (next.x < 0 or next.y < 0) continue;

            const nx: usize = @intCast(next.x);
            const ny: usize = @intCast(next.y);
            if (nx >= width or ny >= height) continue;
            if (distances[ny][nx] != 0xFF) continue;
            if (!is_walkable(context, next)) continue;

            distances[ny][nx] = next_distance;
            queue.appendAssumeCapacity(next);
        }
    }
    return distances;
}
