const std = @import("std");
const maths = @import("../maths.zig");

const Vector2 = maths.geometry.vectors.Vector2;

pub const IsWalkableFn = *const fn (context: *anyopaque, cell: Vector2(i16)) bool;

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
        for (distances) |row| allocator.free(row);
        allocator.free(distances);
    }

    for (distances) |*row| {
        row.* = try allocator.alloc(u8, width);
        @memset(row.*, 0xFF);
    }

    var queue = try std.ArrayList(Vector2(i16)).initCapacity(allocator, width * height);
    defer queue.deinit(allocator);

    try queue.append(allocator, target);
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
            try queue.append(allocator, next);
        }
    }

    return distances;
}
