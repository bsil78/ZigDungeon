const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Actor = @import("Actor.zig");
const Tileset = @import("Tileset.zig");
const Vector = @import("Vector.zig");
const Rect = @import("Rect.zig");
const Cell = @import("Cell.zig");
const Inputs = @import("Inputs.zig");

const Rect2 = Rect.Rect2;
const Vector2 = Vector.Vector2;

const game_name = "Zig Dungeon";
const window_width = 960;
const window_height = 540;
const target_fps = 60;
const background_color = raylib.BLACK;

pub fn main() !void {
    const window_rect = Rect2{ .x = 0, .y = 0, .width = window_width, .height = window_height };

    raylib.InitWindow(window_width, window_height, game_name);
    raylib.SetTargetFPS(target_fps);

    defer raylib.CloseWindow();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    var character = Actor.init("sprites/character/Character.png", Cell{ .x = 1, .y = 1 });
    var level = try Level.init("Levels/Level1.png", "sprites/tilesets/Biome1Tileset.png", &character, &arena);
    defer level.deinit();

    level.tilemap.center(window_rect);

    // Setup the render texture, where the whole game is going to be drawn to
    const render_texture = raylib.LoadRenderTexture(window_width, window_height);
    defer raylib.UnloadRenderTexture(render_texture);

    while (!raylib.WindowShouldClose()) {
        const inputs = Inputs.read();

        level.input(inputs) catch {
            std.debug.print("Cannot go this way", .{});
        };

        if (inputs.hasAction()) {
            inputs.print();
        }

        // Rendering
        raylib.BeginTextureMode(render_texture);
        raylib.ClearBackground(background_color);
        try level.draw();
        raylib.EndTextureMode();

        raylib.BeginDrawing();
        raylib.DrawTexturePro(render_texture.texture, Rect.flipRectY(window_rect), window_rect, Vector.Vector2Zero, 0.0, raylib.WHITE);
        raylib.EndDrawing();
    }
}
