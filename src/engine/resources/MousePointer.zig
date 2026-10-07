// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const raylib = @import("../vendors/vendors.zig").raylib;
const rendering = @import("../core/subsystems/rendering.zig");
const sprite_module = @import("sprites/Sprite.zig");
const AnimatedSprite = @import("sprites/AnimatedSprite.zig").AnimatedSprite;
// #endregion

// #region Concrete imports
const Sprite = sprite_module.Sprite;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
const Transform = rendering.Transform;
const Renderable = rendering.Renderable;
// #endregion

pub fn MousePointer(
    comptime MouseVisuals: type,
    comptime MAX_FRAMES: u8,
    comptime MAX_CONTEXT_SIZE: usize,
) type {
    comptime {
        if (@typeInfo(MouseVisuals) != .@"enum") @compileError("MousePointer MouseVisuals must be an enum");
        if (MAX_FRAMES == 0) @compileError("MousePointer requires capacity for at least one animation/sprite frame");
    }

    const visuals_count = @typeInfo(MouseVisuals).@"enum".fields.len;
    const FirstVisual: MouseVisuals = @enumFromInt(@typeInfo(MouseVisuals).@"enum".fields[0].value);

    const AnimatedSpriteType = AnimatedSprite(1, MAX_FRAMES, MAX_CONTEXT_SIZE);

    return struct {
        const Self = @This();
        const SizedRenderable = Renderable(MAX_CONTEXT_SIZE);

        pub const StateCount = visuals_count;

        pub const VisualType = union(enum) {
            hidden,
            sprite: Sprite,
            animated_sprite: AnimatedSpriteType,
        };

        pub const Config = struct {
            visual: VisualType = .hidden,
            hot_reference: Vector2(f32) = Vector2(f32).Zero(),
            visual_offset: Vector2(f32) = Vector2(f32).Zero(),
            z_layer: i16 = 100,

            pub fn static(
                sprite: Sprite,
                hot_reference: Vector2(f32),
                visual_offset: Vector2(f32),
                z_layer: i16,
            ) Config {
                return .{
                    .visual = .{ .sprite = sprite },
                    .hot_reference = hot_reference,
                    .visual_offset = visual_offset,
                    .z_layer = z_layer,
                };
            }

            pub fn animated(
                sprite: AnimatedSpriteType,
                hot_reference: Vector2(f32),
                visual_offset: Vector2(f32),
                z_layer: i16,
            ) Config {
                return .{
                    .visual = .{ .animated_sprite = sprite },
                    .hot_reference = hot_reference,
                    .visual_offset = visual_offset,
                    .z_layer = z_layer,
                };
            }
        };

        pub const Error = error{
            InvalidVisual,
            InvalidPointerConfig,
        };
        pub const Configurations = [StateCount]Config;

        configurations: Configurations,
        current_state: MouseVisuals = FirstVisual,

        pub fn init(configurations: [StateCount]Config) Error!Self {
            for (&configurations) |*config| {
                try validateConfig(config.*);
            }
            return .{ .configurations = configurations };
        }

        pub fn setVisual(self: *Self, state: MouseVisuals) Error!void {
            const index = visualIndex(state) orelse return Error.InvalidVisual;
            if (self.current_state == state) return;
            self.current_state = state;
            resetAnimation(&self.configurations[index]);
        }

        pub fn reset(self: *Self) void {
            self.current_state = FirstVisual;
            resetAnimation(&self.configurations[visualIndex(FirstVisual).?]);
        }

        pub fn updateAnimation(self: *Self) void {
            const index = visualIndex(self.current_state).?;
            switch (self.configurations[index].visual) {
                .hidden, .sprite => {},
                .animated_sprite => |*sprite| sprite.updateAnimation(),
            }
        }

        pub fn renderable(self: *const Self, mouse_position: Vector2(f32)) ?SizedRenderable {
            const config = self.configurations[visualIndex(self.current_state).?];
            const transform = Transform{
                .position = mouse_position
                    .minus(config.hot_reference)
                    .add(config.visual_offset),
            };
            return switch (config.visual) {
                .hidden => null,
                .sprite => |sprite| spriteRenderable( sprite, transform, config.z_layer),
                .animated_sprite => |sprite| sprite.renderable( transform, config.z_layer),
            };
        }

        fn validateConfig(config: Config) Error!void {
            if (!std.math.isFinite(config.hot_reference.x) or !std.math.isFinite(config.hot_reference.y) or
                !std.math.isFinite(config.visual_offset.x) or !std.math.isFinite(config.visual_offset.y))
            {
                return Error.InvalidPointerConfig;
            }
            switch (config.visual) {
                .hidden => {},
                .sprite => |sprite| {
                    if (sprite.texture.width <= 0 or sprite.texture.height <= 0) {
                        return Error.InvalidPointerConfig;
                    }
                },
                .animated_sprite => |sprite| {
                    if (sprite.animations[0].frame_count == 0 or
                        !std.math.isFinite(sprite.animations[0].frames_per_second) or
                        sprite.animations[0].frames_per_second <= 0)
                    {
                        return Error.InvalidPointerConfig;
                    }
                },
            }
        }

        fn resetAnimation(config: *Config) void {
            switch (config.visual) {
                .animated_sprite => |*sprite| {
                    sprite.animations[0].current_frame = 0;
                    sprite.elapsed_seconds = 0;
                },
                .hidden, .sprite => {},
            }
        }

        fn spriteRenderable(sprite: Sprite, transform: Transform, z_layer: i16) SizedRenderable {
            const texture = sprite.texture;
            const source = Rect(f32).init(
                0,
                0,
                @floatFromInt(texture.width),
                @floatFromInt(texture.height),
            );
            return .{
                .renderingFn = SizedRenderable.drawTexture,
                .renderingCtx = SizedRenderable.textureRegionContext(texture, source, transform),
                .z_layer = z_layer,
            };
        }

        fn visualIndex(state: MouseVisuals) ?usize {
            inline for (@typeInfo(MouseVisuals).@"enum".fields, 0..) |field, index| {
                if (@intFromEnum(state) == field.value) return index;
            }
            return null;
        }
    };
}
