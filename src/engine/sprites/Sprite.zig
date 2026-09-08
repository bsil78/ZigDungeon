// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const raylib = @import("../core/core.zig").raylib;
const renderer = @import("../core/subsystems/renderer.zig");
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
const Transform = maths.geometry.Transform;
const Color = @import("../../libs/gfx/gfx.zig").Color;
const ToRaylib = @import("../core/core.zig").ToRaylib;
// #endregion

const Sprite = @This();

allocator: Allocator,
texture: raylib.Texture2D,
transform: Transform = Transform{},
size: Vector2(f32),
pivot: Vector2(f32) = Vector2(f32).Zero(),
tint: raylib.Color,
z_layer: i16,

pub fn init(allocator: Allocator, image_data: []const u8, z_layer: i16, tint: Color) !*Sprite {
    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    defer raylib.UnloadImage(image);
    const texture = raylib.LoadTextureFromImage(image);
    const ptr = try allocator.create(Sprite);

    ptr.* = Sprite{
        .allocator = allocator,
        .texture = texture,
        .size = Vector2(f32).init(@floatFromInt(texture.width), @floatFromInt(texture.height)),
        .pivot = Vector2(f32).Zero(),
        .tint = ToRaylib(u8).Color(&tint),
        .z_layer = z_layer,
        .transform = Transform{},
    };

    return ptr;
}

pub fn deinit(self: *Sprite) void {
    raylib.UnloadTexture(self.texture);
    self.allocator.destroy(self);
}

pub fn draw(self: *Sprite) void {
    const trans = self.transform.toGlobal();

    raylib.DrawTexturePro(
        self.texture,
        ToRaylib(f32).Rectangle(&(Rect(f32).initV(Vector2(f32).Zero(), self.size))),
        ToRaylib(f32).Rectangle(&(Rect(f32).initV(trans.position.add(self.pivot), self.size.times(trans.scale)))),
        ToRaylib(f32).Vector2(&(self.pivot)),
        maths.geometry.Trigo(f32).radToDeg(&(trans.rotation)),
        self.tint,
    );
}
