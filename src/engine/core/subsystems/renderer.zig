// #region Namespace imports
const std = @import("std");
const maths = @import("../../../libs/maths/maths.zig");
const raylib = @import("../../vendors/raylib.zig").raylib;
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
const ToRaylib = @import("../../vendors/raylib.zig").ToRaylib;
// #endregion

pub const background_color = raylib.BLACK;

pub const Settings = struct {
    window_size: Vector2(u32),
    window_rect: Rect(u32),
    target_fps: u32,
};

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
var settings: ?Settings = null;

pub fn init(alloc: Allocator, user_settings: Settings, game_name: [*c]const u8) !void {
    settings = user_settings;
    const current_settings = settings.?;

    raylib.InitWindow(@intCast(current_settings.window_size.x), @intCast(current_settings.window_size.y), game_name);
    raylib.SetTargetFPS(@intCast(current_settings.target_fps));

    render_texture = raylib.LoadRenderTexture(@intCast(current_settings.window_size.x), @intCast(current_settings.window_size.y));
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
    std.debug.assert(settings != null);
    const current_settings = settings.?;
    const window_rect_f32 = Rect(f32).init(
        @floatFromInt(current_settings.window_rect.x),
        @floatFromInt(current_settings.window_rect.y),
        @floatFromInt(current_settings.window_rect.w),
        @floatFromInt(current_settings.window_rect.h),
    );
    const flipped_window_rect = window_rect_f32.flipRectY();

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
        ToRaylib(f32).Rectangle(&flipped_window_rect),
        ToRaylib(f32).Rectangle(&window_rect_f32),
        ToRaylib(f32).Vector2(&(Vector2(f32).Zero())),
        0.0,
        raylib.WHITE,
    );
    raylib.EndDrawing();
}

pub fn clearRenderQueue() void {
    render_queue.clearRetainingCapacity();
}
