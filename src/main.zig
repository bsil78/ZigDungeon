const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Tileset = @import("Tileset.zig");
const Vector = @import("Vector.zig");
const Rect = @import("Rect.zig");

const Rect2 = Rect.Rect2;
const Vector2 = Vector.Vector2;

const game_name = "Zig Dungeon";
const game_width = 480;
const game_height = 270;
const window_width = 960;
const window_height = 540;
const target_fps = 60;
const background_color = raylib.BLACK;

pub fn main() !void {
    const game_rect = Rect2{ .x = 0, .y = 0, .width = game_width, .height = game_height };
    const window_rect = Rect2{ .x = 0, .y = 0, .width = window_width, .height = window_height };

    raylib.InitWindow(window_width, window_height, game_name);
    raylib.SetTargetFPS(target_fps);

    defer raylib.CloseWindow();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const tileset = try Tileset.initFromSpriteSheet("Sprites/Tilesets/Biome1Tileset.png", &arena);
    var tilemap = try Tilemap.initFromPngFile("Levels/Level1.png", tileset, &arena);

    tilemap.center(game_rect);

    // Setup the render texture, where the whole game is going to be drawn to
    const render_texture = raylib.LoadRenderTexture(game_width, game_height);
    defer raylib.UnloadRenderTexture(render_texture);

    // Rendering loop
    while (!raylib.WindowShouldClose()) {
        raylib.BeginTextureMode(render_texture);
        raylib.ClearBackground(background_color);
        try tilemap.draw();
        raylib.EndTextureMode();

        raylib.BeginDrawing();
        raylib.DrawTexturePro(render_texture.texture, Rect.flipRectY(game_rect), window_rect, Vector.Vector2Zero, 0.0, raylib.WHITE);
        raylib.EndDrawing();
    }
}
