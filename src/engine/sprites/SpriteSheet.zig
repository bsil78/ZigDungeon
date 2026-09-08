// #region Namespace imports
const maths = @import("../../libs/maths/maths.zig");
const raylib = @import("../core/core.zig").raylib;
// #endregion

// #region Concrete imports
const Vector2 = maths.Vector2;
const Rect = maths.Rect;
// #endregion

const SpriteSheet = @This();

texture: raylib.Texture2D,
columns: u16,
lines: u16,

pub fn init(image_data: []const u8, columns: u16, lines: u16) SpriteSheet {
    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    defer raylib.UnloadImage(image);
    return SpriteSheet{
        .texture = raylib.LoadTextureFromImage(image),
        .columns = columns,
        .lines = lines,
    };
}

pub fn getFrameRect(self: *SpriteSheet, frame_id: u32) Rect(f32) {
    const texture_size = Vector2(c_int).init(self.texture.width, self.texture.height).floatFromInt(f32);
    const grid_size = Vector2(u16).init(self.columns, self.lines).floatFromInt(f32);
    const frame_size = texture_size.divide(grid_size);
    const grid_pos = Vector2(u16).init(frame_id % self.columns, frame_id / self.columns).floatFromInt(f32);

    return Rect(f32).initV(grid_pos.times(frame_size), frame_size);
}
