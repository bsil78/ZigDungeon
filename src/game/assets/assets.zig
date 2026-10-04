// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const globals = @import("../globals.zig");
// #endregion

// #region Concrete imports
const Sprite = @import("../../engine/resources/resources.zig").Sprite;
const SpriteSheet = @import("../../engine/resources/resources.zig").SpriteSheet;
const GameTilesSet = @import("../game_types.zig").GameTilesSet;
const GameTilesMap = @import("../game_types.zig").GameTilesMap;
const TileType = @import("../game_enums.zig").TileType;
const LevelId = @import("../game_enums.zig").LevelId;
const Vector2 = libs.maths.geometry.vectors.Vector2;
// #endregion

// sprites
// images
const level1_png = @embedFile("levels/Level1.png");
const levels_png: [1][:0]const u8 = .{level1_png};

pub const Assets = struct {
    character_sprite: Sprite,
    soldier_sprite: Sprite,
    slime_spritesheet: SpriteSheet,
    enemy_actions_arrow: Sprite,
    character_hart: Sprite,
    tileset_spritesheet: SpriteSheet,
    tileset: ?GameTilesSet = null,
    initialized: bool = false,

    pub fn init() !Assets {
        var assets = Assets{
            .character_sprite = Sprite.init(@embedFile("sprites/character/Character.png")),
            .soldier_sprite = Sprite.init(@embedFile("sprites/enemies/Enemy.png")),
            .slime_spritesheet = SpriteSheet.init(@embedFile("sprites/enemies/Slime.png")),
            .enemy_actions_arrow = Sprite.init(@embedFile("sprites/ui/EnemyActions/Arrow.png")),
            .character_hart = Sprite.init(@embedFile("sprites/character/Hart.png")),
            .tileset_spritesheet = SpriteSheet.init(@embedFile("sprites/tilesets/Biome1Tileset.png")),
            .initialized = true,
            // .tileset_spritesheet = SpriteSheet.init(@embedFile("sprites/tilesets/Tileset.png")),
        };
        errdefer assets.deinit();
        assets.tileset = try gameTilesSet(assets.tileset_spritesheet);
        return assets;
    }

    pub fn deinit(self: *Assets) void {
        if (!self.initialized) return;
        if (self.tileset) |*tileset| tileset.deinit();
        self.tileset = null;
        self.character_sprite.deinit();
        self.soldier_sprite.deinit();
        self.slime_spritesheet.deinit();
        self.enemy_actions_arrow.deinit();
        self.character_hart.deinit();
        self.tileset_spritesheet.deinit();
        self.initialized = false;
    }

    pub fn gameTilesSet(spriteSheet: SpriteSheet) !GameTilesSet {
        return try GameTilesSet.initFromSpriteSheet(spriteSheet, Vector2(u8).Zero());
    }

    pub fn gameTilesMap(level: LevelId) !GameTilesMap {
        return try GameTilesMap.initFromPngData(levels_png[@intFromEnum(level)], tileTypeMapper);
    }

    // The tileTypeMapper function maps a color value to a corresponding TileType enum value.
    fn tileTypeMapper(color: u32) globals.TileTypeScalar {
        return switch (color) {
            255 => @intFromEnum(TileType.Wall),
            0 => @intFromEnum(TileType.Ground),
            else => @intFromEnum(TileType.Void),
        };
    }
};
