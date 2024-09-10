const std = @import("std");
const raylib = @import("raylib.zig");
const Vector = @import("Vector.zig");
const Rect = @import("Rect.zig");
const Tileset = @This();

const Texture = raylib.struct_Texture;
const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Rect2 = Rect.Rect2;
const Vector2 = Vector.Vector2;

const TileError = error{OutOfBound};

tile_width: u32 = 32,
tile_height: u32 = 32,
sprite_sheet: Texture,
tiles: ArrayList(Tile),

const Tile = struct {
    sheet_x: f32,
    sheet_y: f32,
    width: f32,
    height: f32,

    fn getRect(self: Tile) Rect2 {
        return Rect2{
            .x = self.sheet_x,
            .y = self.sheet_y,
            .width = self.width,
            .height = self.height,
        };
    }

    pub fn draw(self: Tile, sprite_sheet: Texture, pos: Vector2) void {
        const rect = self.getRect();
        raylib.DrawTextureRec(sprite_sheet, rect, pos, raylib.WHITE);
    }
};

pub fn initFromSpriteSheet(png_file_path: []const u8, arena: *ArenaAllocator) !Tileset {
    var tileset = Tileset{
        .sprite_sheet = raylib.LoadTexture(png_file_path.ptr),
        .tiles = ArrayList(Tile).init(arena.allocator()),
    };

    const sprite_sheet_w: u8 = @intCast(tileset.sprite_sheet.width);
    const sprite_sheet_h: u8 = @intCast(tileset.sprite_sheet.height);
    const nb_col_tiles: usize = sprite_sheet_w / tileset.tile_width;
    const nb_row_tiles: usize = sprite_sheet_h / tileset.tile_height;

    const sprite_sheet_image = raylib.LoadImageFromTexture(tileset.sprite_sheet);
    defer raylib.UnloadImage(sprite_sheet_image);

    for (0..nb_row_tiles) |row| {
        for (0..nb_col_tiles) |col| {
            const x: f32 = @floatFromInt(col * tileset.tile_width);
            const y: f32 = @floatFromInt(row * tileset.tile_height);
            const w: f32 = @floatFromInt(tileset.tile_width);
            const h: f32 = @floatFromInt(tileset.tile_height);
            const rect = Rect2{ .x = x, .y = y, .width = w, .height = h };
            const tile_image = raylib.ImageFromImage(sprite_sheet_image, rect);
            defer raylib.UnloadImage(tile_image);
            const alpha_border = raylib.GetImageAlphaBorder(tile_image, 0.01);

            // Escape fully transparent tiles
            if (alpha_border.width <= 0.0 and alpha_border.height <= 0.0) {
                continue;
            }

            // Add valid tiles to tiles list
            try tileset.tiles.append(Tile{
                .sheet_x = x,
                .sheet_y = y,
                .width = @floatFromInt(tileset.tile_width),
                .height = @floatFromInt(tileset.tile_height),
            });
        }
    }

    return tileset;
}

pub fn drawTile(self: Tileset, tile_id: usize, pos: Vector2) !void {
    if (tile_id >= self.tiles.items.len) {
        return TileError.OutOfBound;
    }

    const tile = self.tiles.items[tile_id];
    tile.draw(self.sprite_sheet, pos);
}
