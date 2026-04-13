const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;

const raylib = @import("../core/core.zig").raylib;
const ToRaylib = @import("../core/core.zig").ToRaylib;
const Tileset = @This();

const Allocator = std.mem.Allocator;
pub const TilesArrayList = std.ArrayList(Tile);
const Texture = raylib.struct_Texture;

const TileError = error{OutOfBound};

tile_width: u32 = 32,
tile_height: u32 = 32,
sprite_sheet: Texture,
tiles: TilesArrayList,

const Tile = struct {
    sheet_x: f32,
    sheet_y: f32,
    width: f32,
    height: f32,

    fn getRect(self: Tile) Rect(f32) {
        return Rect(f32).init(
            self.sheet_x,
            self.sheet_y,
            self.width,
            self.height,
        );
    }

    pub fn draw(self: Tile, sprite_sheet: Texture, pos: Vector2(f32)) void {
        const rect = ToRaylib(f32).Rectangle(&(self.getRect()));
        raylib.DrawTextureRec(sprite_sheet, rect, ToRaylib(f32).Vector2(&(pos)), raylib.WHITE);
    }
};

pub fn initFromSpriteSheet(allocator: Allocator, png_file_path: []const u8) !Tileset {
    var tileset = Tileset{
        .sprite_sheet = raylib.LoadTexture(png_file_path.ptr),
        .tiles = try Tileset.TilesArrayList.initCapacity(allocator,64),
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
            const rect = ToRaylib(f32).Rectangle(&(Rect(f32).init(x, y, w, h)));
            const tile_image = raylib.ImageFromImage(sprite_sheet_image, rect);
            defer raylib.UnloadImage(tile_image);
            const alpha_border = raylib.GetImageAlphaBorder(tile_image, 0.01);

            if (alpha_border.width <= 0.0 and alpha_border.height <= 0.0) {
                continue;
            }

            tileset.tiles.appendAssumeCapacity(Tile{
                .sheet_x = x,
                .sheet_y = y,
                .width = @floatFromInt(tileset.tile_width),
                .height = @floatFromInt(tileset.tile_height),
            });
        }
    }

    return tileset;
}

pub fn drawTile(self: Tileset, tile_id: usize, pos: Vector2(f32)) !void {
    if (tile_id >= self.tiles.items.len) {
        return TileError.OutOfBound;
    }

    const tile = self.tiles.items[tile_id];
    tile.draw(self.sprite_sheet, pos);
}
