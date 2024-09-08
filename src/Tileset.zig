const std = @import("std");
const raylib = @import("raylib.zig");
const Tileset = @This();
const Image = raylib.struct_Image;
const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Rect = raylib.struct_Rectangle;

const TileError = error{OutOfBound};

tile_width: u32 = 16,
tile_height: u32 = 16,
sprite_sheet: Image,
tiles: ArrayList(Image),

pub fn initFromSpriteSheet(png_file_path: []const u8, arena: *ArenaAllocator) !Tileset {
    var tileset = Tileset{
        .sprite_sheet = raylib.LoadImage(png_file_path.ptr),
        .tiles = ArrayList(Image).init(arena.allocator()),
    };

    const sprite_sheet_w: u8 = @intCast(tileset.sprite_sheet.width);
    const sprite_sheet_h: u8 = @intCast(tileset.sprite_sheet.height);
    const nb_col_tiles: usize = sprite_sheet_w / tileset.tile_width;
    const nb_row_tiles: usize = sprite_sheet_h / tileset.tile_height;

    for (0..nb_row_tiles) |row| {
        for (0..nb_col_tiles) |col| {
            const x: f32 = @floatFromInt(col * tileset.tile_width);
            const y: f32 = @floatFromInt(row * tileset.tile_height);
            const w: f32 = @floatFromInt(tileset.tile_width);
            const h: f32 = @floatFromInt(tileset.tile_height);
            const rect = Rect{ .x = x, .y = y, .width = w, .height = h };
            const tile_image = raylib.ImageFromImage(tileset.sprite_sheet, rect);
            const alpha_border = raylib.GetImageAlphaBorder(tile_image, 0.01);

            // Escape fully transparent tiles
            if (alpha_border.width <= 0.0 and alpha_border.height <= 0.0) {
                continue;
            }

            try tileset.tiles.append(tile_image);
        }
    }

    return tileset;
}

pub fn getTileImage(self: Tileset, tile_index: u16) TileError!Image {
    if (tile_index >= self.tiles.items.len) {
        return TileError.OutOfBound;
    }

    return self.tiles.items[tile_index];
}
