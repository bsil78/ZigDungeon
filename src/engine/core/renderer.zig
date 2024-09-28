const std = @import("std");
const raylib = @import("raylib.zig");
const project_settings = @import("project_settings.zig");
const Vector2 = @import("Vector.zig").Vector2;
const Rect = @import("Rect.zig").Rect;

pub const window_size = Vector2(u32).init(960, 540);
pub const window_rect = Rect(f32).initV(Vector2(f32).Zero(), window_size.floatFromInt(f32));

const background_color = raylib.BLACK;
var render_texture: raylib.RenderTexture2D = undefined;

fn init() !void {
    render_texture = raylib.LoadRenderTexture(window_size.x, window_size.y);
    defer raylib.UnloadRenderTexture(render_texture);

    raylib.InitWindow(window_size.x, window_size.y, project_settings.game_name);
    raylib.SetTargetFPS(project_settings.target_fps);
}

pub fn render() !void {
    raylib.BeginTextureMode(render_texture);
    raylib.ClearBackground(background_color);

    raylib.EndTextureMode();
    raylib.BeginDrawing();
    raylib.DrawTexturePro(
        render_texture.texture,
        window_rect.flipRectY().toRaylib(),
        window_rect.toRaylib(),
        Vector2(f32).Zero().toRaylib(),
        0.0,
        raylib.WHITE,
    );
    raylib.EndDrawing();
}

pub fn drawTexture() !void {}
