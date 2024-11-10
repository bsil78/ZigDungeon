const std = @import("std");
const raylib = engine.core.raylib;
const engine = @import("engine/engine.zig");
const project_settings = engine.core.project_settings;
const Level = @import("game/Level.zig");
const Actor = @import("game/Actor.zig");
const Combat = @import("game/Combat.zig");
const Tileset = engine.tiles.Tileset;
const Tilemap = engine.tiles.Tilemap;
const Vector2 = engine.maths.Vector.Vector2;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try engine.init();
    defer engine.deinit();

    var level = try Level.init(allocator, "Levels/Level1.png", "sprites/tilesets/Biome1Tileset.png");

    level.tilemap.center(project_settings.window_rect);

    const character = try Actor.init(allocator, "sprites/character/Character.png", Vector2(i16).One(), Actor.ActorType.Character, level);
    const enemy = try Actor.init(allocator, "sprites/character/Enemy.png", Vector2(i16).init(2, 1), Actor.ActorType.Enemy, level);

    try level.addActor(character);
    try level.addActor(enemy);

    var combat = try Combat.init(allocator, level);
    defer combat.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.mainLoop();
    }

    defer raylib.CloseWindow();
}
