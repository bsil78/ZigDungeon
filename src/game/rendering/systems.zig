// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const engine = @import("../../engine/engine.zig");
const raylib = @import("../../engine/vendors/raylib.zig").raylib;
const renderer = engine.core.renderer;
const globals = @import("../globals.zig");
const messages = globals.messages;
// #endregion

// #region Concrete imports
const Tilemap = engine.tiles.Tilemap;
const GameWorld = @import("../world/world.zig").GameWorld;
const Sprite = engine.sprites.Sprite;
const Character = @import("../character/character.zig").Character;
const Enemy = @import("../enemy/enemy.zig").Enemy;
const Renderable = @import("components.zig").Renderable;
const Transform = maths.geometry.Transform;
// #endregion

fn healthBarColor(health_ratio: f32) raylib.Color {
    var ratio = health_ratio;
    if (ratio < 0.0) ratio = 0.0;
    if (ratio > 1.0) ratio = 1.0;

    if (ratio >= 2.0 / 3.0) return .{ .r = 0, .g = 255, .b = 0, .a = 255 };
    if (ratio <= 1.0 / 3.0) return .{ .r = 255, .g = 0, .b = 0, .a = 255 };

    const t = (ratio - 1.0 / 3.0) / (1.0 / 3.0);
    return .{
        .r = @as(u8, @intFromFloat(255.0 * (1.0 - t))),
        .g = @as(u8, @intFromFloat(255.0 * t)),
        .b = 0,
        .a = 255,
    };
}

fn drawHealthBar(pointer: *anyopaque) void {
    const sprite: *Sprite = @ptrCast(@alignCast(pointer));
    const entity: *Character = @ptrCast(@alignCast(sprite));
    _ = entity;
}

pub fn queueTilemap(tilemap: *Tilemap) !void {
    const render = struct {
        fn draw(pointer: *anyopaque) void {
            const map: *Tilemap = @ptrCast(@alignCast(pointer));
            map.render() catch |err| std.debug.print(messages.tilemap_render_error, .{err});
        }
    };
    try renderer.addToRenderQueue(0, render.draw, @ptrCast(tilemap));
}

pub fn queueEntities(world: *GameWorld) !void {
    if (world.character) |*character| {
        try queue(&character.renderable, character.world_transform.world);
        try queueCharacterHealthBar(character);
    }
    for (world.enemies.items) |*enemy| {
        try queue(&enemy.renderable, enemy.world_transform.world);
        try queueEnemyHealthBar(enemy);
    }
}

fn queueCharacterHealthBar(character: *Character) !void {
    const render = struct {
        fn draw(pointer: *anyopaque) void {
            const entity: *Character = @ptrCast(@alignCast(pointer));
            const sprite: *Sprite = @ptrCast(@alignCast(entity.renderable.sprite));
            const bar_width: f32 = 16.0;
            const bar_height: f32 = 4.0;
            const health_ratio = @as(f32, @floatFromInt(entity.health.hp)) / @as(f32, @floatFromInt(entity.health.max_hp));
            const x = entity.world_transform.world.position.x + (sprite.size.x / 2.0) - (bar_width / 2.0);
            const y = entity.world_transform.world.position.y - 2.0;
            const fill_width = bar_width * health_ratio;

            const border_x: i32 = @intFromFloat(x - 1.0);
            const border_y: i32 = @intFromFloat(y - 1.0);
            const border_w: i32 = @intFromFloat(bar_width + 2.0);
            const border_h: i32 = @intFromFloat(bar_height + 2.0);

            raylib.DrawRectangle(border_x, border_y, border_w, border_h, raylib.BLACK);
            raylib.DrawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(fill_width), @intFromFloat(bar_height), healthBarColor(health_ratio));
        }
    };

    try renderer.addToRenderQueue(character.renderable.z_layer + 1, render.draw, @ptrCast(character));
}

fn queueEnemyHealthBar(enemy: *Enemy) !void {
    const render = struct {
        fn draw(pointer: *anyopaque) void {
            const entity: *Enemy = @ptrCast(@alignCast(pointer));
            const sprite: *Sprite = @ptrCast(@alignCast(entity.renderable.sprite));
            const bar_width: f32 = 16.0;
            const bar_height: f32 = 4.0;
            const health_ratio = @as(f32, @floatFromInt(entity.health.hp)) / @as(f32, @floatFromInt(entity.health.max_hp));
            const x = entity.world_transform.world.position.x + (sprite.size.x / 2.0) - (bar_width / 2.0);
            const y = entity.world_transform.world.position.y - 2.0;
            const fill_width = bar_width * health_ratio;

            const border_x: i32 = @intFromFloat(x - 1.0);
            const border_y: i32 = @intFromFloat(y - 1.0);
            const border_w: i32 = @intFromFloat(bar_width + 2.0);
            const border_h: i32 = @intFromFloat(bar_height + 2.0);

            raylib.DrawRectangle(border_x, border_y, border_w, border_h, raylib.BLACK);
            raylib.DrawRectangle(@intFromFloat(x), @intFromFloat(y), @intFromFloat(fill_width), @intFromFloat(bar_height), healthBarColor(health_ratio));
        }
    };

    try renderer.addToRenderQueue(enemy.renderable.z_layer + 1, render.draw, @ptrCast(enemy));
}

fn queue(renderable: *Renderable, transform: Transform) !void {
    const sprite: *Sprite = @ptrCast(@alignCast(renderable.sprite));
    sprite.transform = transform;
    try renderer.addToRenderQueue(renderable.z_layer, drawSprite, renderable.sprite);
}

fn drawSprite(pointer: *anyopaque) void {
    const sprite: *Sprite = @ptrCast(@alignCast(pointer));
    sprite.draw();
}

pub fn clearQueue() void {
    renderer.clearRenderQueue();
}
