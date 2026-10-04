// #region Namespace imports
const libs = @import("../../../libs/libs.zig");
const engine = @import("../../engine.zig");
const raylib = engine.vendors.raylib;
// #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
// #endregion

const Sprite = @This();

texture: raylib.Texture2D,

pub fn init(image_data: []const u8) Sprite {
    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    defer raylib.UnloadImage(image);
    const texture = raylib.LoadTextureFromImage(image);
    return Sprite{
        .texture = texture,
    };
}

pub fn size(self: *Sprite) Vector2(u16) {
    return Vector2(u16).init(@intCast(self.texture.width), @intCast(self.texture.height));
}

pub fn deinit(self: *Sprite) void {
    raylib.UnloadTexture(self.texture);
}
