const raylib = @import("raylib.zig");
const Cell = @import("Cell.zig");
pub const Vector2 = raylib.Vector2;

pub const Vector2Zero = Vector2{ .x = 0, .y = 0 };
pub const Vector2Up = Vector2{ .x = 0, .y = -1 };
pub const Vector2Down = Vector2{ .x = 0, .y = 1 };
pub const Vector2Right = Vector2{ .x = 1, .y = 0 };
pub const Vector2Left = Vector2{ .x = -1, .y = 0 };

pub const CardinalDirections = Vector2[4]{
    Vector2Right,
    Vector2Down,
    Vector2Left,
    Vector2Up,
};

pub fn vecToCell(vec: Vector2) Cell {
    return Cell{
        .x = @intFromFloat(vec.x),
        .y = @intFromFloat(vec.y),
    };
}
