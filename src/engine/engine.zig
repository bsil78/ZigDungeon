// #region Namespace imports
const std = @import("std");
const libs = @import("../libs/libs.zig");
const rendering = @import("core/core.zig").rendering;
const inputs = @import("core/core.zig").inputs;
// #endregion

// #region Concrete imports
const Color = libs.gfx.Color;
const Renderer = rendering.Renderer;
const Timer = libs.time.measurement.Timer;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
const GameRandom = @import("core/core.zig").random.GameRandom;
const RandomMode = @import("core/core.zig").random.RandomMode;
// #endregion

pub const resources = @import("resources/resources.zig");
pub const utils = @import("utils/utils.zig");
pub const vendors = @import("vendors/vendors.zig");
pub const core = @import("core/core.zig");

pub const EngineSettings = struct {
    target_fps: u8,
    window_size: Vector2(u32),
    window_rect: Rect(u32),
    game_name: [:0]const u8,
    random_mode: RandomMode,
};

pub fn Instance(comptime MAX_RENDERABLES: u16, comptime MAX_CONTEXT_SIZE: usize) type {
    return struct {
        pub const EngineInstance = Instance(MAX_RENDERABLES, MAX_CONTEXT_SIZE);
        pub const RendererInstance = Renderer(MAX_RENDERABLES, MAX_CONTEXT_SIZE);

        pub const Error = error{
            GameLoopFailed,
        };

        random: GameRandom = undefined,
        frames_count: u32 = 0,
        renderer: RendererInstance = undefined,
        timer: Timer = undefined,

        pub fn init(settings: EngineSettings) !EngineInstance {
            return EngineInstance{
                .random = try GameRandom.init(settings.random_mode),
                .timer = Timer.init(),
                .renderer = try RendererInstance.init(.{
                    .window_size = settings.window_size,
                    .window_rect = settings.window_rect,
                    .target_fps = settings.target_fps,
                }, settings.game_name),
            };
        }

        pub fn process(self: *EngineInstance, game_loop: *const fn (f32) Error!void) !void {
            _ = try self.timer.lap();
            const delta = vendors.raylib.GetFrameTime();
            self.frames_count += 1;
            try game_loop(delta);
            try self.renderer.render();
            self.renderer.clearRenderingQueue();
        }

        pub fn processTime(self: *EngineInstance) f32 {
            return @as(f32, @floatFromInt(Timer.getNs() - self.timer.startTime)) / 1000.0;
        }
    };
}
