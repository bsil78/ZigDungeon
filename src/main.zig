const std = @import("std");


const Vector2 = @import("libs/maths/maths.zig").geometry.vectors.Vector2;

const engine = @import("engine/engine.zig");
const raylib = engine.core.raylib;
const Tileset = engine.tiles.Tileset;
const Tilemap = engine.tiles.Tilemap;
const project_settings = engine.core.project_settings;

const GameWorld = @import("game/world.zig").GameWorld;
const systems = @import("game/systems.zig");
const factories = @import("game/factories.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try engine.init(allocator);
    defer engine.deinit();

    const tileset = try Tileset.initFromSpriteSheet(allocator, "sprites/tilesets/Biome1Tileset.png");
    const tilemap = try Tilemap.initFromPngFile(allocator, "Levels/Level1.png", tileset);
    tilemap.center(project_settings.window_rect);

    var world = try GameWorld.init(allocator, tilemap);
    defer world.deinit();

    _ = try factories.createCharacter(&world, allocator, "sprites/character/Character.png", Vector2(i16).One());
    _ = try factories.createEnemy(&world, allocator, "sprites/enemies/Enemy.png", Vector2(i16).init(2, 1));

    while (!raylib.WindowShouldClose()) {
        try engine.mainLoop();

        const inputs = engine.core.Inputs.read();

        try systems.inputSystem(&world, &inputs);
        try systems.processSystem(&world, allocator);
        systems.resolveActions(&world);

        systems.updateTransformsSystem(&world);

        try systems.renderTilemap(tilemap);
        try systems.renderSystem(&world);
        try engine.render();

        systems.clearRenderQueue();
        systems.clearActionPlans(&world); 
    }

    defer raylib.CloseWindow();
}
