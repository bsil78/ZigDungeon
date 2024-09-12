const Vector = @import("Vector.zig");
const Cell = @This();
const Vector2 = Vector.Vector2;

x: i16,
y: i16,

pub fn toVec(self: Cell) Vector2 {
    return Vector2{
        .x = @floatFromInt(self.x),
        .y = @floatFromInt(self.y),
    };
}

pub fn fromVec(vec: Vector2) Cell {
    return Cell{
        .x = @intFromFloat(vec.x),
        .y = @intFromFloat(vec.y),
    };
}

pub fn add(a: Cell, b: Cell) Cell {
    return Cell{
        .x = a.x + b.x,
        .y = a.y + b.y,
    };
}

pub fn equal(a: Cell, b: Cell) bool {
    return a.x == b.x and a.y == b.y;
}
