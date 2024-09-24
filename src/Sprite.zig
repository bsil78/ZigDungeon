const std = @import("std");
const raylib = @import("raylib.zig");
const Transform = @import("Transform.zig");
const Vector2 = @import("Vector.zig").Vector2;
const Rect = @import("Rect.zig").Rect;
const Sprite = @This();

texture: raylib.Texture2D,
transform: Transform = Transform{},
size: Vector2(f32),
pivot: Vector2(f32) = Vector2(f32).Zero(),

pub fn init(texture_path: []const u8) Sprite {
    const texture = raylib.LoadTexture(texture_path.ptr);

    return Sprite{
        .texture = texture,
        .size = Vector2(f32).init(@floatFromInt(texture.width), @floatFromInt(texture.height)),
    };
}

pub fn draw(self: *Sprite, opt_transform: ?*const Transform) void {
    const result_trans = if (opt_transform) |trans| self.transform.xform(trans) else self.transform;

    raylib.DrawTexturePro(
        self.texture,
        Rect(f32).initV(Vector2(f32).Zero(), self.size).toRaylib(),
        Rect(f32).initV(result_trans.position, self.size.times(result_trans.scale)).toRaylib(),
        self.pivot.toRaylib(),
        self.transform.rotation,
        raylib.WHITE,
    );
}
