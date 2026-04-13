const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const maths = @import("../../../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.Rect;

const raylib = @import("../../vendors/raylib.zig").raylib;
const ToRaylib = @import("../../vendors/raylib.zig").ToRaylib;

const project_settings = @import("project_settings.zig");


pub const background_color = raylib.BLACK;

pub const RenderItem = struct {
    render_fn: *const fn (*anyopaque) void,
    render_ptr: *anyopaque,
    z_layer: i16,
};

var render_texture: raylib.RenderTexture2D = undefined;
var allocator: Allocator = undefined;
var render_queue: std.ArrayListUnmanaged(RenderItem) = .{
    .items = &.{},
    .capacity = 0,
};

pub fn init(alloc: Allocator) !void {
    raylib.InitWindow(project_settings.window_size.x, project_settings.window_size.y, project_settings.game_name);
    raylib.SetTargetFPS(project_settings.target_fps);

    render_texture = raylib.LoadRenderTexture(project_settings.window_size.x, project_settings.window_size.y);
    allocator = alloc;
}

pub fn deinit() void {
    raylib.UnloadRenderTexture(render_texture);
    render_queue.deinit(allocator);
}

pub fn addToRenderQueue(
    z_layer: i16,
    render_fn: *const fn (*anyopaque) void,
    render_ptr: *anyopaque,
) !void {
    try render_queue.append(allocator, RenderItem{
        .render_fn = render_fn,
        .render_ptr = render_ptr,
        .z_layer = z_layer,
    });
}

pub fn render() !void {
    raylib.BeginTextureMode(render_texture);
    raylib.ClearBackground(background_color);

    std.mem.sort(RenderItem, render_queue.items, {}, struct {
        pub fn lessThan(_: void, lhs: RenderItem, rhs: RenderItem) bool {
            return lhs.z_layer < rhs.z_layer;
        }
    }.lessThan);

    for (render_queue.items) |item| {
        item.render_fn(item.render_ptr);
    }

    raylib.EndTextureMode();

    raylib.BeginDrawing();
    raylib.DrawTexturePro(
        render_texture.texture,
        ToRaylib(f32).Rectangle(&(project_settings.window_rect.flipRectY())),
        ToRaylib(f32).Rectangle(&(project_settings.window_rect)),
        ToRaylib(f32).Vector2(&(Vector2(f32).Zero())),
        0.0,
        raylib.WHITE,
    );
    raylib.EndDrawing();
}

pub fn clearRenderQueue() void {
    render_queue.clearRetainingCapacity();
}
