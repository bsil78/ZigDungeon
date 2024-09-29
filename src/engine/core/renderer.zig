const std = @import("std");
const raylib = @import("raylib.zig");
const project_settings = @import("project_settings.zig");
const maths = @import("../maths/maths.zig");
const traits = @import("../traits/traits.zig");
const Allocator = std.mem.Allocator;
const Vector2 = maths.Vector2;
const Rect = maths.Rect;
const RenderTrait = traits.RenderTrait;

pub const background_color = raylib.BLACK;
var render_texture: raylib.RenderTexture2D = undefined;
var render_queue: std.ArrayList(*RenderTrait) = undefined;

const RendererError = error{renderItemNotFound};

pub fn init(allocator: Allocator) !void {
    raylib.InitWindow(project_settings.window_size.x, project_settings.window_size.y, project_settings.game_name);
    raylib.SetTargetFPS(project_settings.target_fps);

    render_texture = raylib.LoadRenderTexture(project_settings.window_size.x, project_settings.window_size.y);
    defer raylib.UnloadRenderTexture(render_texture);

    render_queue = std.ArrayList(*RenderTrait).init(allocator);
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

pub fn addToRenderQueue(render_trait: *RenderTrait) !void {
    try render_queue.append(render_trait);
}

pub fn removeFromRenderQueue(render_trait: *RenderTrait) !void {
    for (render_queue.items, 0..) |item, i| {
        if (item == render_trait) {
            try render_queue.swapRemove(i);
            return;
        }
    }

    return RendererError.renderItemNotFound;
}
