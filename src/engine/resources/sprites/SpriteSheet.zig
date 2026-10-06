// #region Namespace imports
const std = @import("std");
const maths = @import("../../../libs/maths/maths.zig");
const engine = @import("../../engine.zig");
const raylib = engine.vendors.raylib;
const rlh = engine.vendors.raylib_helper;
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
// #endregion

const SpriteSheet = @This();

texture: raylib.Texture2D,
size: Vector2(u16),

pub fn init(image_data: []const u8) SpriteSheet {
    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    defer raylib.UnloadImage(image);
    const texture = raylib.LoadTextureFromImage(image);
    return SpriteSheet{
        .texture = texture,
        .size = Vector2(u16).init(@intCast(texture.width), @intCast(texture.height)),
    };
}

pub fn getRegionTexture(self: *const SpriteSheet, region: Rect(u16)) !raylib.Texture2D {
    if (!Rect(u16).initV(self.size).containsRect(region)) {
        std.debug.panic("Region {any} is somewhat outside of AtlasTexture {any} bounds", .{ region, self.size });
    }
    return rlh.extractSubTexture(self.texture, region);
}

pub fn deinit(self: *SpriteSheet) void {
    raylib.UnloadTexture(self.texture);
}
