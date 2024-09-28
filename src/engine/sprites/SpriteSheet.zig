const raylib = @import("raylib.zig");
const Vector2 = @import("Vector.zig").Vector2;
const Rect = @import("Rect.zig").Rect;
const SpriteSheet = @This();

texture: raylib.Texture2D,
columns: u16,
lines: u16,

pub fn init(texture_path: []const u8, columns: u16, lines: u16) SpriteSheet {
    return SpriteSheet{
        .texture = raylib.LoadTexture(texture_path.ptr),
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
