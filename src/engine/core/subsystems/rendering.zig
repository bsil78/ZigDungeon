// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const geometry = libs.maths.geometry;
const raylib = @import("../../vendors/vendors.zig").raylib;
const rlh = @import("../../vendors/vendors.zig").raylib_helper;
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const LimitedQueue = libs.datastructs.LimitedQueue;
const Color = libs.gfx.Color;
// #endregion

pub const Transform = @import("Transform.zig").Transform;
pub const Renderable = @import("Renderable.zig").Renderable;
pub const Settings = struct { window_size: Vector2(u32), window_rect: Rect(u32), target_fps: u32, background_color: Color = Color.BLACK };

pub fn Renderer(comptime QUEUE_SIZE: u16, comptime MAX_CONTEXT_SIZE: usize) type {
    const SizedRenderable = Renderable(MAX_CONTEXT_SIZE);

    return struct {
        render_texture: raylib.RenderTexture2D,
        rendering_queue: [QUEUE_SIZE]SizedRenderable = undefined,
        queue_size: u16 = 0,
        settings: Settings,

        pub const RENDERABLE_CONTEXT_SIZE = MAX_CONTEXT_SIZE;

        pub fn init(renderer_settings: Settings, game_name: [:0]const u8) !Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE) {
            raylib.InitWindow(  @intCast(renderer_settings.window_size.x), 
                                @intCast(renderer_settings.window_size.y), 
                                @ptrCast(game_name.ptr));
            raylib.SetExitKey(raylib.KEY_F12);
            raylib.SetTargetFPS(@intCast(renderer_settings.target_fps));
            return Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE){
                .settings = renderer_settings,
                .render_texture = raylib.LoadRenderTexture(@intCast(renderer_settings.window_size.x), @intCast(renderer_settings.window_size.y)),
            };
        }

        pub fn deinit(self: *Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE)) void {
            raylib.UnloadRenderTexture(self.render_texture);
        }

        pub fn addToRenderQueue(self: *Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE), renderable: SizedRenderable) !void {
            if (self.queue_size == QUEUE_SIZE) {
                std.debug.panic("Render queue (size : {d}) is full ! \n\tmake it bigger or add less elements to render", .{self.queue_size});
            }
            //std.log.info("Added id {d}", .{renderable.id});
            self.rendering_queue[self.queue_size] = renderable;
            self.queue_size = self.queue_size + 1;
        }

        pub fn render(self: *Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE)) !void {
            const window_rect_f32 = Rect(f32).init(
                @floatFromInt(self.settings.window_rect.x),
                @floatFromInt(self.settings.window_rect.y),
                @floatFromInt(self.settings.window_rect.w),
                @floatFromInt(self.settings.window_rect.h),
            );
            // rendering des éléments du jeu
            raylib.BeginTextureMode(self.render_texture);
            raylib.ClearBackground(rlh.toRaylibColor(self.settings.background_color));

            var sort_index: u16 = 1;
            while (sort_index < self.queue_size) : (sort_index += 1) {
                const current = self.rendering_queue[sort_index];
                var insertion_index = sort_index;
                while (insertion_index > 0 and
                    self.rendering_queue[insertion_index - 1].z_layer > current.z_layer)
                {
                    self.rendering_queue[insertion_index] = self.rendering_queue[insertion_index - 1];
                    insertion_index -= 1;
                }
                self.rendering_queue[insertion_index] = current;
            }

            for (0..self.queue_size) |i| {
                const renderable_ptr: *const SizedRenderable = &self.rendering_queue[i];
                //std.log.info("rendering [{d}]\n", .{ renderable_ptr.id });
                renderable_ptr.renderingFn(@constCast(&renderable_ptr.renderingCtx));
            }
            raylib.EndTextureMode();

            // affichage à l'écran
            const flipped_window_rect = window_rect_f32.flipRectY();
            raylib.BeginDrawing();
            raylib.DrawTexturePro(
                self.render_texture.texture,
                rlh.toRaylibRectangle(flipped_window_rect),
                rlh.toRaylibRectangle(window_rect_f32),
                rlh.toRaylibVector2(Vector2(f32).Zero()),
                0.0,
                raylib.WHITE,
            );
            raylib.EndDrawing();
        }

        pub fn clearRenderingQueue(self: *Renderer(QUEUE_SIZE, MAX_CONTEXT_SIZE)) void {
            self.queue_size = 0;
        }
    };
}
