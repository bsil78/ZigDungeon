const raylib = @import("raylib.zig");
const Vector = @import("Vector.zig");
const Vector2 = Vector.Vector2;

pub const Rect2 = raylib.struct_Rectangle;

pub fn centerRect(container_rect: Rect2, rect: Rect2) Rect2 {
    return Rect2{
        .x = container_rect.x + (container_rect.width / 2.0) - (rect.width / 2.0),
        .y = container_rect.y + (container_rect.height / 2.0) - (rect.height / 2.0),
        .width = rect.width,
        .height = rect.height,
    };
}

pub fn flipRectY(rect: Rect2) Rect2 {
    return Rect2{ .x = rect.x, .y = rect.y, .width = rect.width, .height = -rect.height };
}

pub fn getRectPosition(rect: Rect2) Vector2 {
    return Vector2{ .x = rect.x, .y = rect.y };
}

pub fn getRectSize(rect: Rect2) Vector2 {
    return Vector2{ .x = rect.width, .y = rect.height };
}
