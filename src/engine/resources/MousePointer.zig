// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const raylib = libs.vendors.raylib;
const rendering = @import("../core/subsystems/rendering.zig");
const sprite_module = @import("sprites/Sprite.zig");
const AnimatedSprite = @import("sprites/AnimatedSprite.zig").AnimatedSprite;
// #endregion

// #region Concrete imports
const Sprite = sprite_module.Sprite;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
const SizedRenderable = rendering.Renderable;
const Transform = rendering.Transform;
// #endregion

pub fn MousePointer(
    comptime State: type,
    comptime MAX_FRAMES: u8,
    comptime MAX_CONTEXT_SIZE: usize,
) type {
    comptime {
        if (@typeInfo(State) != .@"enum") @compileError("MousePointer state must be an enum");
        if (MAX_FRAMES == 0) @compileError("MousePointer requires capacity for at least one animation frame");
    }

    const state_count = @typeInfo(State).@"enum".fields.len;
    const FirstState: State = @enumFromInt(@typeInfo(State).@"enum".fields[0].value);
    const Renderable = SizedRenderable(MAX_CONTEXT_SIZE);
    const AnimatedSpriteType = AnimatedSprite(1, MAX_FRAMES, MAX_CONTEXT_SIZE);

    return struct {
        pub const StateCount = state_count;

        pub const Visual = union(enum) {
            hidden,
            sprite: Sprite,
            animated_sprite: AnimatedSpriteType,
        };

        pub const Config = struct {
            visual: Visual = .hidden,
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
            InvalidState,
            InvalidPointerConfig,
        };
        pub const Configurations = [StateCount]Config;

        configurations: Configurations,
        current_state: State = FirstState,

        pub fn init(configurations: [StateCount]Config) Error!Self {
            for (&configurations) |*config| {
                try validateConfig(config.*);
            }
            return .{ .configurations = configurations };
        }

        pub fn setState(self: *Self, state: State) Error!void {
            const index = stateIndex(state) orelse return error.InvalidState;
            if (self.current_state == state) return;
            self.current_state = state;
            resetAnimation(&self.configurations[index]);
        }

        pub fn update(self: *Self, delta_seconds: f32) void {
            const index = stateIndex(self.current_state).?;
            switch (self.configurations[index].visual) {
                .hidden, .sprite => {},
                .animated_sprite => |*sprite| sprite.update(delta_seconds),
            }
        }

        pub fn reset(self: *Self) void {
            self.current_state = FirstState;
            resetAnimation(&self.configurations[stateIndex(FirstState).?]);
        }

        pub fn renderable(self: *const Self, id: u16, mouse_position: Vector2(f32)) ?Renderable {
            const config = self.configurations[stateIndex(self.current_state).?];
            const transform = Transform{
                .position = mouse_position
                    .minus(config.hot_reference)
                    .add(config.visual_offset),
            };
            return switch (config.visual) {
                .hidden => null,
                .sprite => |sprite| spriteRenderable(id, sprite, transform, config.z_layer),
                .animated_sprite => |sprite| sprite.renderable(id, transform, config.z_layer),
            };
        }

        const Self = @This();

        fn validateConfig(config: Config) Error!void {
            if (!std.math.isFinite(config.hot_reference.x) or !std.math.isFinite(config.hot_reference.y) or
                !std.math.isFinite(config.visual_offset.x) or !std.math.isFinite(config.visual_offset.y))
            {
                return error.InvalidPointerConfig;
            }
            switch (config.visual) {
                .hidden => {},
                .sprite => |sprite| {
                    if (sprite.texture.width <= 0 or sprite.texture.height <= 0) {
                        return error.InvalidPointerConfig;
                    }
                },
                .animated_sprite => |sprite| {
                    if (sprite.animations[0].frame_count == 0 or
                        !std.math.isFinite(sprite.animations[0].frames_per_second) or
                        sprite.animations[0].frames_per_second <= 0)
                    {
                        return error.InvalidPointerConfig;
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

        fn spriteRenderable(id: u16, sprite: Sprite, transform: Transform, z_layer: i16) Renderable {
            const texture = sprite.texture;
            const source = Rect(f32).init(
                0,
                0,
                @floatFromInt(texture.width),
                @floatFromInt(texture.height),
            );
            return .{
                .id = id,
                .renderingFn = Renderable.drawTexture,
                .renderingCtx = Renderable.textureRegionContext(texture, source, transform),
                .z_layer = z_layer,
            };
        }

        fn stateIndex(state: State) ?usize {
            inline for (@typeInfo(State).@"enum".fields, 0..) |field, index| {
                if (@intFromEnum(state) == field.value) return index;
            }
            return null;
        }
    };
}
