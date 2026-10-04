// #region Namespace imports
const std = @import("std");
const libs = @import("../libs/libs.zig");
const geometry = libs.maths.geometry;
const raylib = libs.vendors.raylib;
const engine = @import("../engine/engine.zig");
const random = @import("../engine/core/core.zig").random;
const enums = @import("game_enums.zig");
pub const asset_data = @import("assets/assets.zig");
// #endregion

// #region Concrete imports
const UserSettings = @import("../engine/core/core.zig").UserSettings;
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Timer = libs.time.measurement.Timer;
const GameRandom = random.GameRandom;
// #endregion

pub const TileTypeScalar = @typeInfo(enums.TileType).@"enum".tag_type;
pub const WINDOW_SIZE = Vector2(u32).init(960, 540);
pub const TILES_SIZE = Vector2(u16).initOneValue(32);
const tilesTypeSize = @typeInfo(TileTypeScalar).int.bits;
pub const TILES_MAX_COUNT: TileTypeScalar = @as(TileTypeScalar, 1) << (tilesTypeSize - 1);
comptime {
    std.debug.assert(TILES_MAX_COUNT > 0);
}
pub const EntityId = u16;
pub const CHARACTER_ENTITY_ID: EntityId = 0;
pub const MAX_SOLDIERS: usize = 3;
pub const MAX_SLIMES: usize = 3;
pub const FIRST_SOLDIER_ENTITY_ID: EntityId = 1;
pub const FIRST_SLIME_ENTITY_ID: EntityId = @intCast(1 + MAX_SOLDIERS);
pub const MAX_ENTITIES: usize = 1 + MAX_SOLDIERS + MAX_SLIMES;
pub const WORLD_SIZE_SCALAR = u8;
pub const WORLD_SIZE = Vector2(WORLD_SIZE_SCALAR).initOneValue(16);
pub const WORLD_LEN: u16 = @as(u16, WORLD_SIZE.x) * @as(u16, WORLD_SIZE.y);
pub const MAX_RENDERABLES = MAX_ENTITIES * 2 + WORLD_LEN;

pub const assets = struct {
    pub const character_sprite = asset_data.character_sprite;
    pub const soldier_sprite = asset_data.soldier_sprite;
    pub const tileset = asset_data.tileset;
    pub const level = asset_data.level;
};

pub const messages = struct {
    pub const tilemap_render_error = "Tilemap render error: {}\n";
};

pub fn project_settings() !UserSettings {
    var timer = Timer{};
    const seed = timer.start();
    return .{
        // The project_settings module contains global configuration settings for the game, such as target FPS, window size, and game name.
        // The live RNG uses the timer seed; repeatable runs require a fixed or replay seed.

        .target_fps = 60,
        .window_size = WINDOW_SIZE,
        .window_rect = Rect(u32).initV(WINDOW_SIZE),
        .game_name = "Zig Dungeon",
        .random_mode = .{
            .live = try random.LiveRandom.init(seed, struct {
                fn flush(_: *const [512]u64) GameRandom.Error!void {
                    //do nothing
                }
            }.flush),
        },
    };
}
