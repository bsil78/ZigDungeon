// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const geometry = libs.maths.geometry;
const raylib = @import("../../vendors/vendors.zig").raylib;
const rlh = @import("../../vendors/vendors.zig").raylib_helper;
// #endregion

// #region Concrete imports
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Color = libs.gfx.Color;
const Texture2D = raylib.Texture2D;
const TypesHelper = libs.utils.TypesHelper;
const SpriteSheet = @import("../resources.zig").SpriteSheet;
// #endregion

/// Represents a tile texture extracted from a sprite sheet, with a tint.
pub fn Tile(comptime size: Vector2(u16)) type {
    return struct {
        texture: Texture2D,
        tint: Color = Color.WHITE,

        pub fn init(spriteSheet: SpriteSheet, tile_pos: Vector2(u16)) !Tile(size) {
            return .{ .texture = try spriteSheet.getRegionTexture(Rect(u16).initPV(tile_pos, size)) };
        }

        /// Draws this tile's stored texture at the specified position using its tint.
        pub fn draw(self: Tile(size), pos: Vector2(f32)) void {
            const rlpos = pos.as(i32);
            raylib.DrawTexture(self.texture, rlpos.x, rlpos.y, rlh.toRaylibColor(self.tint));
        }

        pub fn deinit(self: *Tile(size)) void {
            raylib.UnloadTexture(self.texture);
        }
    };
}

/// count is tiles set size
pub fn TilesSet(comptime count: anytype, comptime tilesSize: Vector2(u16)) type {
    TypesHelper.assert(@TypeOf(count), TypesHelper.Asserts.unsigned_int, "tiles count type");

    return struct {
        pub const TC = @TypeOf(count);
        pub const COUNT: TC = count;
        pub const TILE_SIZE = tilesSize;

        tiles: [COUNT]Tile(TILE_SIZE) = undefined,
        initialized_count: usize = 0,

        pub const Error: type = error{
            OutOfBound,
            SpriteSheetTooSmall,
        };

        // produces a Tileset from a sprite sheet image data, extracting individual tiles based on the specified tile width and height.
        pub fn initFromSpriteSheet(spriteSheet: SpriteSheet, spacing: Vector2(u8)) Error!TilesSet(count, tilesSize) {
            var tilesSet = TilesSet(count, tilesSize){};
            errdefer tilesSet.deinit();
            const nb_col_tiles: u8 = @intCast(spriteSheet.size.x / tilesSize.x);
            const nb_row_tiles: u8 = @intCast(spriteSheet.size.y / tilesSize.y);

            if (nb_col_tiles * nb_row_tiles < count) return Error.SpriteSheetTooSmall;

            // Iterates through the sprite sheet image
            // and extracts individual tiles based on the specified tile width and height.
            // It checks for non-transparent tiles and adds them to the tileset's tile list.
            var tileId: usize = 0;

            for (0..nb_row_tiles) |row| {
                for (0..nb_col_tiles) |col| {
                    const col8: u8 = @intCast(col);
                    const row8: u8 = @intCast(row);
                    const x: u16 = col8 * (tilesSize.x + spacing.x);
                    const y: u16 = row8 * (tilesSize.y + spacing.y);
                    const pos = Vector2(u16).init(x, y);
                    var tile = try Tile(tilesSize).init(spriteSheet, pos);
                    const image = raylib.LoadImageFromTexture(tile.texture);
                    defer raylib.UnloadImage(image);
                    const alpha_border = raylib.GetImageAlphaBorder(image, 0.01);
                    if (alpha_border.width <= 0.0 and alpha_border.height <= 0.0) {
                        tile.deinit();
                        continue;
                    }
                    tilesSet.tiles[tileId] = tile;
                    tileId += 1;
                    tilesSet.initialized_count = tileId;
                    if (tileId == count) return tilesSet;
                }
            }
            return tilesSet;
        }

        pub fn deinit(self: *TilesSet(count, tilesSize)) void {
            for (self.tiles[0..self.initialized_count]) |*tile| {
                tile.deinit();
            }
            self.initialized_count = 0;
        }
    };
}
