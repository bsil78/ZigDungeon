// #region Namespace imports
const std = @import("std");
const libs = @import("../libs/libs.zig");
const engine = @import("../engine/engine.zig");
const core = engine.core;
const resources = engine.resources;
const globals = @import("globals.zig");
const raylib = engine.vendors.raylib;
// #endregion

// #region Concrete imports
const Vector2 = @import("../libs/libs.zig").maths.geometry.vectors.Vector2;
const Renderable = core.rendering.Renderable;
// #endregion

pub const GameTilesSet = resources.TilesSet(globals.TILES_MAX_COUNT, globals.TILES_SIZE);
pub const GameTilesMap = resources.TilesMap(@TypeOf(globals.TILES_MAX_COUNT), globals.WORLD_SIZE);
pub const WorldCell = Vector2(globals.WORLD_SIZE_SCALAR);
comptime {
    std.debug.assert(@typeInfo(@TypeOf(GameTilesMap.SIZE)).@"struct".fields.len == 2);
    std.debug.assert(GameTilesMap.TILE_TYPE == globals.TileTypeScalar);
}
const MAP_RENDERING_CONTEXT = struct {
    tilesMap: GameTilesMap,
    tilesSet: *const GameTilesSet,
};
const MAX_RENDERING_CONTEXT_SIZE = @max(@sizeOf(MAP_RENDERING_CONTEXT), @sizeOf(raylib.Texture2D));
pub const GameRenderer = core.rendering.Renderer(globals.MAX_RENDERABLES, MAX_RENDERING_CONTEXT_SIZE);
pub const GameResources = struct {
    tilesMap: GameTilesMap = undefined,
};
pub const SizedRenderable = Renderable(GameRenderer.RENDERABLE_CONTEXT_SIZE);
