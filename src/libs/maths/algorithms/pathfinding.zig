// #region Namespace imports
const std = @import("std");
const maths = @import("../maths.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const LimitedQueue = @import("../../datastructs/limited_queue.zig").LimitedQueue;
// #endregion

pub fn IsWalkableFn(comptime V: anytype) type {
    return *const fn (context: *anyopaque, cell: V) bool;
}

// Computes the breadth-first distances from the target cell to all other cells in the grid.
// It returns a flat row-major array of distances, indexed as y * width + x.
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
    comptime ARRAY_SIZE: usize,
    comptime VType: type,
    target: VType,
    width: usize,
    height: usize,
    context: *anyopaque,
    is_walkable: IsWalkableFn(VType),
) ![ARRAY_SIZE]u8 {
    const VTypeScalar: type = VType.SCALAR;

    const Queue = LimitedQueue(ARRAY_SIZE, VType);
    var distances: [ARRAY_SIZE]u8 = undefined;

    @memset(&distances, 0xFF);

    var queue: Queue = Queue{};

    const initialPos = target.y * width + target.x;
    distances[initialPos] = 0;
    try queue.push(target);

    while (!queue.isEmpty()) {
        const current = try queue.pop();
        const cellIndex = current.y * width + current.x;
        const current_distance = distances[cellIndex];
        //std.log.info("Current : {any}\n", .{current});
        //std.log.info("Distance : {d}\n", .{current_distance});
        const next_distance: u8 = current_distance + 1;

        for (Vector2(i16).cardinalDirections()) |direction| {
            const next: VType = current.as(i16).add(&direction).as(VTypeScalar);
            if (next.x < 0 or next.y < 0) continue;
            const nx: usize = @intCast(next.x);
            const ny: usize = @intCast(next.y);
            if (nx >= width or ny >= height) continue;
            if (distances[ny * width + nx] != 0xFF) continue;
            if (!is_walkable(context, next)) continue;
            const nextIndex = ny * width + nx;
            std.debug.assert(next_distance != 0xFF);
            distances[nextIndex] = next_distance;
            try queue.push(next);
        }
    }

    // for (distances, 0..) |d, i| {
    //     if (i % width == 0) {
    //         std.log.info("\n", .{});
    //     }
    //     std.log.info("{x:0>2} ", .{d});
    // }
    // std.log.info("\n", .{});

    return distances;
}
