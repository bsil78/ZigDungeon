// #region Namespace imports
const raylib = @import("../../engine/vendors/raylib.zig").raylib;
const engine = @import("../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Sprite = engine.sprites.Sprite;
// #endregion

pub const Renderable = struct {
    sprite: *anyopaque,
    z_layer: i16 = 0,
    tint: raylib.Color = raylib.WHITE,

    pub fn destroySprite(renderable: *Renderable) void {
        const sprite: *Sprite = @ptrCast(@alignCast(renderable.sprite));
        sprite.deinit();
    }
};
