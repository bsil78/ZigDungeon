const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Tileset = @import("Tileset.zig");

const game_name = "Zig Dungeon";
const game_width = 480;
const game_height = 270;
const window_width = 960;
const window_height = 540;
const target_fps = 60;
const background_color = raylib.BLACK;

pub fn main() !void {
    raylib.InitWindow(window_width, window_height, game_name);
    raylib.SetTargetFPS(target_fps);

    defer raylib.CloseWindow();

    //var buffer: [10000]u8 = undefined;
    //var fba = std.heap.FixedBufferAllocator.init(&buffer);
    //const allocator = fba.allocator();
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const tileset = try Tileset.initFromSpriteSheet("Sprites/Tilesets/Biome1Tileset.png", &arena);
    const tilemap = try Tilemap.initFromPngFile("Levels/Level1.png", tileset, &arena);
    var render_image = raylib.GenImageColor(game_width, game_height, raylib.BLUE);

    const game_rect = raylib.Rectangle{ .x = 0, .y = 0, .width = game_width, .height = game_height };
    const window_rect = raylib.Rectangle{ .x = 0, .y = 0, .width = window_width, .height = window_height };

    while (!raylib.WindowShouldClose()) {
        raylib.BeginDrawing();
        defer raylib.EndDrawing();

        raylib.ClearBackground(background_color);
        try tilemap.draw(&render_image);
        const render_texture = raylib.LoadTextureFromImage(render_image);
        raylib.DrawTexturePro(render_texture, game_rect, window_rect, raylib.Vector2{ .x = 0, .y = 0 }, 0.0, raylib.WHITE);
    }
}
