// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const raylib = @import("../../vendors/vendors.zig").raylib;
const rendering = @import("../../core/core.zig").rendering;
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
const AnimatedSpriteConfig = @import("AnimatedSpriteConfig.zig").AnimatedSpriteConfig;
const Transform = rendering.Transform;
const Renderable = rendering.Renderable;
// #endregion

pub fn AnimatedSprite(
    comptime ANIMATIONS_COUNT: u8,
    comptime MAX_FRAMES: u8,
    comptime MAX_CONTEXT_SIZE: usize,
) type {
    comptime {
        if (ANIMATIONS_COUNT == 0) @compileError("AnimatedSprite requires at least one animation");
        if (MAX_FRAMES == 0) @compileError("Animation requires capacity for at least one frame");
    }

    const SizedRenderable = Renderable(MAX_CONTEXT_SIZE);

    return struct {
        pub const Config = AnimatedSpriteConfig(MAX_FRAMES);
        pub const Error = error{
            NonExistingAnimation,
        } || Config.Error;

        pub const Frame = struct {
            texture: raylib.Texture2D,
            source: Rect(f32),
        };

        pub const Animation = struct {
            frames: [MAX_FRAMES]Frame,
            frame_count: u8,
            current_frame: u8 = 0,
            frames_per_second: f32,
            loop: bool,

            pub fn init(texture: raylib.Texture2D, config: Config) Error!Animation {
                const texture_width: f32 = @floatFromInt(texture.width);
                const texture_height: f32 = @floatFromInt(texture.height);
                try config.validateForTexture(texture_width, texture_height);
                var frames: [MAX_FRAMES]Frame = undefined;

                for (config.regions[0..config.frame_count], 0..) |region, index| {
                    frames[index] = .{ .texture = texture, .source = region };
                }

                return .{
                    .frames = frames,
                    .frame_count = config.frame_count,
                    .frames_per_second = config.frames_per_second,
                    .loop = config.loop,
                };
            }

            fn advance(self: *Animation, frame_steps: usize) void {
                if (self.loop) {
                    self.current_frame = @intCast((@as(usize, self.current_frame) + frame_steps) % self.frame_count);
                } else {
                    const last_frame = self.frame_count - 1;
                    const remaining = last_frame - self.current_frame;
                    self.current_frame += @intCast(@min(frame_steps, remaining));
                }
            }
        };

        animations: [ANIMATIONS_COUNT]Animation,
        current_animation: u8,
        elapsed_seconds: f64 = 0,

        const Self = @This();

        pub fn init(animations: [ANIMATIONS_COUNT]Animation, default_animation: u8) Error!Self {
            if (default_animation >= ANIMATIONS_COUNT) return Error.NonExistingAnimation;
            return .{
                .animations = animations,
                .current_animation = default_animation,
            };
        }

        pub fn setAnimation(self: *Self, animation_index: u8) Error!void {
            if (animation_index >= ANIMATIONS_COUNT) return Error.NonExistingAnimation;
            if (self.current_animation == animation_index) return;

            self.current_animation = animation_index;
            self.animations[animation_index].current_frame = 0;
            self.elapsed_seconds = 0;
        }

        pub fn updateAnimation(self: *Self) void {
            const delta_time = raylib.GetFrameTime();
            var animation = &self.animations[self.current_animation];
            if (!animation.loop and animation.current_frame == animation.frame_count - 1) return;

            const interval = 1.0 / @as(f64, animation.frames_per_second);
            const elapsed = self.elapsed_seconds + @as(f64, delta_time);
            const complete_steps_float = @floor(elapsed / interval);

            if (animation.loop) {
                const step_remainder = @mod(complete_steps_float, @as(f64, @floatFromInt(animation.frame_count)));
                animation.advance(@intFromFloat(step_remainder));
                self.elapsed_seconds = @mod(elapsed, interval);
            } else {
                const remaining = animation.frame_count - 1 - animation.current_frame;
                const steps: usize = @intFromFloat(@min(complete_steps_float, @as(f64, @floatFromInt(remaining))));
                animation.advance(steps);
                if (steps == remaining) {
                    self.elapsed_seconds = 0;
                } else {
                    self.elapsed_seconds = elapsed - @as(f64, @floatFromInt(steps)) * interval;
                }
            }
        }

        pub fn currentFrame(self: *const Self) Frame {
            const animation = &self.animations[self.current_animation];
            return animation.frames[animation.current_frame];
        }

        pub fn renderable(
            self: *const Self,
            visual_transform: Transform,
            z_layer: i16,
        ) SizedRenderable {
            const frame = self.currentFrame();
            return .{
                .renderingFn = SizedRenderable.drawTexture,
                .renderingCtx = SizedRenderable.textureRegionContext(frame.texture, frame.source, visual_transform),
                .z_layer = z_layer,
            };
        }
    };
}
