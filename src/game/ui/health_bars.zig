// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const vendors = @import("../../engine/vendors/vendors.zig");
const raylib = vendors.raylib;
const rlh = vendors.raylib_helper;
const core = @import("../../engine/core/core.zig");
const rendering = core.rendering;
const resources = @import("../../engine/resources/resources.zig");
const globals = @import("../globals.zig");
const messages = globals.messages;
const types = @import("../game_types.zig");
// #endregion

// #region Concrete imports
const Layers = @import("../game_enums.zig").Layers;
const Tilemap = resources.TilesMap;
const GameWorld = @import("../../game/world.zig").GameWorld;
const SizedRenderable = types.SizedRenderable;
const Health = @import("../components/health.zig").Health;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Color = libs.gfx.Color;
// #endregion

const HealthBarStyle = struct {
    width: f32 = 16.0,
    height: f32 = 4.0,
    background_color: Color = Color.BLACK,
    ok_color: Color = Color.GREEN,
    ko_color: Color = Color.RED,

    fn color(self: *const HealthBarStyle, health_ratio: f32) Color {
        var ratio = health_ratio;
        if (ratio < 0.0) ratio = 0.0;
        if (ratio > 1.0) ratio = 1.0;

        if (ratio >= 2.0 / 3.0) return self.ok_color;
        if (ratio <= 1.0 / 3.0) return self.ko_color;

        const t = (ratio - 1.0 / 3.0) / (1.0 / 3.0);
        return Color.lerp_opaque(self.ko_color, self.ok_color, t);
    }
};

fn drawHealthBar(health: Health, absoluteCenterBottomPosition: Vector2(f32), style: HealthBarStyle) void {
    const x = absoluteCenterBottomPosition.x - (style.width / 2.0);
    const y = absoluteCenterBottomPosition.y - style.height;

    const raw_health_ratio = if (health.max_hp == 0)
        0.0
    else
        @as(f32, @floatFromInt(health.hp)) / @as(f32, @floatFromInt(health.max_hp));
    const health_ratio = @min(raw_health_ratio, 1.0);
    const fill_width = style.width * health_ratio;

    const border_x: i32 = @intFromFloat(x - 1.0);
    const border_y: i32 = @intFromFloat(y - 1.0);
    const border_w: i32 = @intFromFloat(style.width + 2.0);
    const border_h: i32 = @intFromFloat(style.height + 2.0);

    raylib.DrawRectangle(border_x, border_y, border_w, border_h, rlh.toRaylibColor(style.background_color));
    raylib.DrawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(fill_width), @intFromFloat(style.height), rlh.toRaylibColor(style.color(health_ratio)));
}

const characterHealtBarStyle = HealthBarStyle{};

pub fn characterHealthBar(health: Health, width: f32, visual_transform: rendering.Transform) !SizedRenderable {
    return computeRenderableHealthBar(health, width, visual_transform, characterHealtBarStyle, @intFromEnum(Layers.CHARACTER_HB));
}

const enemyHealtBarStyle = HealthBarStyle{};

pub fn enemyHealthBar(health: Health, width: f32, visual_transform: rendering.Transform) !SizedRenderable {
    return computeRenderableHealthBar(health, width, visual_transform, enemyHealtBarStyle, @intFromEnum(Layers.ENEMIES_HB));
}

fn computeRenderableHealthBar(health: Health, width: f32, visual_transform: rendering.Transform, style: HealthBarStyle, z_layer: i16) !SizedRenderable {
    const centerBottomPos = Vector2(f32){
        .x = visual_transform.position.x + width * visual_transform.scale.x / 2.0,
        .y = visual_transform.position.y - 2.0,
    };
    const CONTEXT = struct {
        health: Health,
        centerBottomPos: Vector2(f32),
        style: HealthBarStyle,
    };

    const myctx = CONTEXT{ .health = health, .centerBottomPos = centerBottomPos, .style = style };

    return SizedRenderable{ 
        .renderingFn = struct {
            fn draw(ctx: *anyopaque) void {
                const context: CONTEXT = SizedRenderable.restoreContext(CONTEXT,ctx);
                drawHealthBar(context.health, context.centerBottomPos, context.style);
            }
        }.draw, 
        .renderingCtx = SizedRenderable.contextCopy(CONTEXT, &myctx), .z_layer = z_layer };
}
