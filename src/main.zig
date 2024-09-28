const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Actor = @import("Actor.zig");
const Tileset = @import("Tileset.zig");
const Vector2 = @import("vector.zig").Vector2;
const Inputs = @import("Inputs.zig");
const Globals = @import("Globals.zig");
const renderer = @import("renderer.zig");
const engine_events = @import("engine_events.zig");

const game_name = "Zig Dungeon";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try Globals.init();
    try engine_events.init(allocator);

    defer raylib.CloseWindow();

    var character = try Actor.init("sprites/character/Character.png", Vector2(i16).One(), Actor.ActorType.Character, allocator);
    var enemy = try Actor.init("sprites/character/Enemy.png", Vector2(i16).init(2, 1), Actor.ActorType.Enemy, allocator);

    var level = try Level.init("Levels/Level1.png", "sprites/tilesets/Biome1Tileset.png", allocator);
    try level.addActor(&character);
    try level.addActor(&enemy);

    level.tilemap.center(Globals.window_rect);

    while (!raylib.WindowShouldClose()) {
        Globals.process();

        const inputs = Inputs.read();
        try level.input(&inputs);

        try renderer.render();
    }
}
