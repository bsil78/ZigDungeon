// #region Namespace imports
const std = @import("std");
const Layers = @import("../game_enums.zig").Layers;
const vendors = @import("../../libs/vendors/vendors.zig");
const clay = vendors.clay;
const clayh = vendors.clay_helper;
const game_inputs = @import("../game_inputs.zig");
// #endregion

// #region Concrete imports
const Rect = @import("../../libs/libs.zig").maths.geometry.shapes.Rect;
const Vector2 = @import("../../libs/libs.zig").maths.geometry.vectors.Vector2;
const SizedRenderable = @import("../game_types.zig").SizedRenderable;
// #endregion

const GameMenu = @This();

var _pointer_position: clay.Vector2 = .{ .x = 0, .y = 0 };
var _pointer_down = false;
var _pointer_pressed = false;
var _start_pressed = false;

var _start_button_id: clay.ElementId = undefined;

pub fn init() void {
    _start_button_id = .ID("StartButton");
}

pub fn hide() void {
    _start_pressed = false;
}

pub fn startButtonPressed() bool {
    return _start_pressed;
}

pub fn screen() SizedRenderable {
    const mouseState = game_inputs.mouseState();
    const mousePosition = game_inputs.mouseGamePosition();
    _pointer_pressed = mouseState.isButtonPressed(.left);
    _pointer_down = mouseState.isButtonDown(.left);
    _pointer_position = .{
        .x = mousePosition.x,
        .y = mousePosition.y,
    };
    return SizedRenderable{
        .renderingFn = struct {
            fn draw_go(_: *anyopaque) void {
                GameMenu.draw();
            }
        }.draw_go,
        .z_layer = @intFromEnum(Layers.GAME_OVER),
    };
}

fn draw() void {
    clay.setPointerState(_pointer_position, _pointer_down);
    clay.beginLayout();
    clay.UI()(.{
        .id = .ID("GameOverRoot"),
        .layout = .{
            .sizing = .grow,
            .direction = .top_to_bottom,
            .child_alignment = .center,
        },
        .background_color = .{ 8, 10, 14, 205 },
    })({
        clay.UI()(.{
            .id = .ID("GameMenuPanel"),
            .layout = .{
                .sizing = .{ .w = .fixed(440), .h = .fixed(250) },
                .direction = .top_to_bottom,
                .padding = .all(24),
                .child_gap = 18,
                .child_alignment = .center,
            },
            .background_color = .{ 30, 34, 42, 255 },
            .corner_radius = .all(6),
        })({
            clay.text("Zig Dungeon", .{
                .font_size = 42,
                .color = .{ 176, 84, 176, 255 },
                .alignment = .center,
            });
            clay.text("A sandbox gaming project for improving Zig mastering", .{
                .font_size = 20,
                .color = .{ 220, 224, 230, 255 },
                .alignment = .center,
            });
            clay.UI()(.{
                .id = _start_button_id,
                .layout = .{
                    .sizing = .{ .w = .fixed(240), .h = .fixed(54) },
                    .child_alignment = .center,
                },
                .background_color = if (clay.hovered()) .{ 92, 174, 118, 255 } else .{ 66, 139, 91, 255 },
                .corner_radius = .all(4),
            })({
                clay.text("START RUN", .{
                    .font_size = 22,
                    .color = .{ 255, 255, 255, 255 },
                    .alignment = .center,
                });
            });
        });
    });
    const commands = clay.endLayout();
    _start_pressed = _pointer_pressed and clay.pointerOver(_start_button_id);
    clayh.renderCommands(commands);
}
