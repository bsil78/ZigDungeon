const std = @import("std");
const raylib = @import("raylib.zig").raylib;
const project_settings = @import("project_settings.zig");
const maths = @import("../maths/maths.zig");
const traits = @import("../traits/traits.zig");
const Allocator = std.mem.Allocator;
const Vector2 = maths.Vector2;
const Rect = maths.Rect;
const RenderTrait = traits.RenderTrait;
const ArrayList = std.ArrayList;

pub const background_color = raylib.BLACK;
var render_texture: raylib.RenderTexture2D = undefined;
var render_queue: std.AutoHashMap(i16, *ArrayList(*const RenderTrait)) = undefined;
var allocator: Allocator = undefined;

const RendererError = error{renderItemNotFound};

pub fn init(alloc: Allocator) !void {
    raylib.InitWindow(project_settings.window_size.x, project_settings.window_size.y, project_settings.game_name);
    raylib.SetTargetFPS(project_settings.target_fps);

    render_texture = raylib.LoadRenderTexture(project_settings.window_size.x, project_settings.window_size.y);
    render_queue = std.AutoHashMap(i16, *ArrayList(*const RenderTrait)).init(alloc);

    allocator = alloc;
}

pub fn deinit() void {
    raylib.UnloadRenderTexture(render_texture);
    render_queue.deinit();
}

pub fn render() !void {
    raylib.BeginTextureMode(render_texture);
    raylib.ClearBackground(background_color);

    var iterator = render_queue.iterator();

    while (iterator.next()) |entry| {
        for (entry.value_ptr.*.items) |render_trait| {
            try render_trait.render(render_trait.ptr);
        }
    }

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
    if (render_queue.get(render_trait.z_layer)) |array| {
        array.appendAssumeCapacity(render_trait);
    } else {
        const ptr = try allocator.create(ArrayList(*const RenderTrait));
        ptr.* = try ArrayList(*const RenderTrait).initCapacity(allocator,16);
        ptr.*.appendAssumeCapacity(render_trait);
        try render_queue.put(render_trait.z_layer, ptr);
    }
}

pub fn removeFromRenderQueue(render_trait: *RenderTrait) !void {
    if (render_queue.get(render_trait.z_layer)) |array| {
        for (array.items, 0..) |elem, i| {
            if (elem.ptr != render_trait.ptr) {
                continue;
            }

            _ = array.swapRemove(i);
            return;
        }
    }
    return RendererError.renderItemNotFound;
}
