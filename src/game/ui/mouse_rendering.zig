// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
const types = @import("../game_types.zig");
const raylib = engine.vendors.raylib;
// #endregion

// #region Concrete imports
const Vector2 = @import("../../libs/libs.zig").maths.geometry.vectors.Vector2;
// #endregion

pub const MouseVisual = enum {
    arrow,
};

pub const Pointer = engine.resources.MousePointer(
    MouseVisual,
    8,
    types.GameRenderer.RENDERABLE_CONTEXT_SIZE,
);
pub const PointerConfigurations = Pointer.Configurations;
pub const PointerConfig = Pointer.Config;

var pointer: Pointer = undefined;

pub fn initialize(configurations: PointerConfigurations) Pointer.Error!void {
    pointer = try Pointer.init(configurations);
}

pub fn resetPointer() void {
    pointer.reset();
}

pub fn update(state: MouseVisual) void {
    const delta_time = engine.getFrameTime();
    pointer.setState(state) catch unreachable;
    pointer.update(delta_time);
}

pub fn addToRenderQueue(renderer: *types.GameRenderer, mouse_position: Vector2(f32)) !void {
    if (pointer.renderable(std.math.maxInt(u16), mouse_position)) |pointer_renderable| {
        try renderer.addToRenderQueue(pointer_renderable);
    }
}
