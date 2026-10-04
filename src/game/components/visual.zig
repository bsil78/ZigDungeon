// #region Namespace imports
const libs = @import("../../libs/libs.zig");
const engine = @import("../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
// #endregion

pub const Visual = struct {
    texture: engine.vendors.raylib.Texture2D,
    source: ?Rect(f32) = null,
    z_layer: i16,

    pub fn width(self: Visual) i32 {
        return if (self.source) |source| @intFromFloat(source.w) else self.texture.width;
    }

    pub fn height(self: Visual) i32 {
        return if (self.source) |source| @intFromFloat(source.h) else self.texture.height;
    }
};
