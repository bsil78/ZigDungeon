// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const raylib = @import("../core/core.zig").raylib;
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
const Allocator = std.mem.Allocator;
const ToRaylib = @import("../core/core.zig").ToRaylib;
// #endregion

const Tileset = @This();
pub const TilesArrayList = std.ArrayList(Tile);
const Texture = raylib.struct_Texture;

const TileError = error{OutOfBound};

tile_width: u32 = 32,
tile_height: u32 = 32,
sprite_sheet: Texture,
tiles: TilesArrayList,

// Represents an individual tile in the tileset, with properties for its position and size within the sprite sheet
const Tile = struct {
    sheet_x: f32,
    sheet_y: f32,
    width: f32,
    height: f32,

    // Returns a rectangle representing the tile's position and size within the sprite sheet.
    fn getRect(self: Tile) Rect(f32) {
        return Rect(f32).init(
            self.sheet_x,
            self.sheet_y,
            self.width,
            self.height,
        );
    }

    // Draws the tile on the screen at a specified position using the provided sprite sheet texture.
    pub fn draw(self: Tile, sprite_sheet: Texture, pos: Vector2(f32)) void {
        const rect = ToRaylib(f32).Rectangle(&(self.getRect()));
        raylib.DrawTextureRec(sprite_sheet, rect, ToRaylib(f32).Vector2(&(pos)), raylib.WHITE);
    }
};


// produces a Tileset from a sprite sheet image data, extracting individual tiles based on the specified tile width and height.
pub fn initFromSpriteSheet(allocator: Allocator, image_data: []const u8) !Tileset {
    var tileset = Tileset{
        .sprite_sheet = undefined,
        .tiles = try Tileset.TilesArrayList.initCapacity(allocator,64),
    };

    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    defer raylib.UnloadImage(image);
    tileset.sprite_sheet = raylib.LoadTextureFromImage(image);

    const sprite_sheet_w: u8 = @intCast(tileset.sprite_sheet.width);
    const sprite_sheet_h: u8 = @intCast(tileset.sprite_sheet.height);
    const nb_col_tiles: usize = sprite_sheet_w / tileset.tile_width;
    const nb_row_tiles: usize = sprite_sheet_h / tileset.tile_height;

    const sprite_sheet_image = raylib.LoadImageFromTexture(tileset.sprite_sheet);
    defer raylib.UnloadImage(sprite_sheet_image);


    // Iterates through the sprite sheet image
    // and extracts individual tiles based on the specified tile width and height.
    // It checks for non-transparent tiles and adds them to the tileset's tile list.
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

// Draws a specific tile from the tileset at a given position on the screen.
pub fn drawTile(self: Tileset, tile_id: usize, pos: Vector2(f32)) !void {
    if (tile_id >= self.tiles.items.len) {
        return TileError.OutOfBound;
    }
    const tile = self.tiles.items[tile_id];
    tile.draw(self.sprite_sheet, pos);
}
