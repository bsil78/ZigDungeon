// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
const globals = @import("../globals.zig");
const Layers = @import("../game_enums.zig").Layers;
const raylib = engine.vendors.raylib;
// #endregion

// #region Concrete imports
const Rect = @import("../../libs/libs.zig").maths.geometry.shapes.Rect;
const SizedRenderable = @import("../game_types.zig").SizedRenderable;
// #endregion

const GameOver = @This();
var _ws: Rect(u32) = undefined;

pub fn screen(window_size: Rect(u32)) SizedRenderable {
    _ws = window_size;
    return SizedRenderable{
        .id = 0b1111111111111111,
        .renderingFn = struct {
            fn draw_go(_: *anyopaque) void {
                GameOver.draw();
            }
        }.draw_go,
        .z_layer = @intFromEnum(Layers.GAME_OVER),
    };
}

// Renders a "Game Over" overlay on the screen when the player loses the game.
fn draw() void {
    //std.log.info("GO_WS : {any}", .{_ws});
    const width = @as(i32, @intCast(_ws.w));
    const height = @as(i32, @intCast(_ws.h));
    const title = "GAME OVER";
    const restart = "Press R or Enter to restart";

    const title_size: i32 = 56;
    const subtitle_size: i32 = 24;

    const title_width = raylib.MeasureText(title, title_size);
    const restart_width = raylib.MeasureText(restart, subtitle_size);
    const center = _ws.getRectSize().divide(2);
    const twidth = @max(@as(u32, @intCast(title_width)), @as(u32, @intCast(restart_width))) + 50;
    const rect = Rect(u32){ .x = center.x - (@divTrunc(twidth, 2)), .y = center.y - 100, .w = twidth, .h = 200 };

    raylib.DrawRectangle(@intCast(rect.x), @intCast(rect.y), @intCast(rect.w), @intCast(rect.h), raylib.ColorAlpha(.{}, 0.8));
    raylib.DrawText(title, @divTrunc(width - title_width, 2), @divTrunc(height, 2) - title_size - 5, title_size, raylib.RED);
    raylib.DrawText(restart, @divTrunc(width - restart_width, 2), @divTrunc(height, 2) + 5, subtitle_size, raylib.WHITE);
}
