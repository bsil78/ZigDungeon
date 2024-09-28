const std = @import("std");
const raylib = @import("raylib.zig");
const project_settings = @import("project_settings.zig");
const maths = @import("../maths/maths.zig");
const Vector2 = maths.Vector2;
const Rect = maths.Rect;

pub const background_color = raylib.BLACK;
var render_texture: raylib.RenderTexture2D = undefined;

fn init() !void {
    render_texture = raylib.LoadRenderTexture(project_settings.window_size.x, project_settings.window_size.y);
    defer raylib.UnloadRenderTexture(render_texture);

    raylib.InitWindow(project_settings.window_size.x, project_settings.window_size.y, project_settings.game_name);
    raylib.SetTargetFPS(project_settings.target_fps);
}

pub fn render() !void {
    raylib.BeginTextureMode(render_texture);
    raylib.ClearBackground(background_color);

    raylib.EndTextureMode();
    raylib.BeginDrawing();
    raylib.DrawTexturePro(
        render_texture.texture,
        project_settings.window_rect.flipRectY().toRaylib(),
        project_settings.window_rect.toRaylib(),
        Vector2(f32).Zero().toRaylib(),
        0.0,
        raylib.WHITE,
    );
    raylib.EndDrawing();
}

pub fn drawTexture() !void {}
