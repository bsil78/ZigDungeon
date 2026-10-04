// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
const types = @import("../game_types.zig");
// #endregion

// #region Concrete imports
const Vector2 = @import("../../libs/libs.zig").maths.geometry.vectors.Vector2;
// #endregion

pub const State = enum {
    running,
    game_over,
};

pub const Pointer = engine.resources.MousePointer(
    State,
    8,
    types.GameRenderer.RENDERABLE_CONTEXT_SIZE,
);
pub const PointerConfig = Pointer.Config;

var pointer: Pointer = undefined;

pub fn initialize(configurations: Pointer.Configurations) Pointer.Error!void {
    pointer = try Pointer.init(configurations);
}

pub fn beginRun() void {
    pointer.reset();
}

pub fn update(state: State, delta_seconds: f32) void {
    pointer.setState(state) catch unreachable;
    pointer.update(delta_seconds);
}

pub fn addToRenderQueue(renderer: *types.GameRenderer, mouse_position: Vector2(f32)) !void {
    if (pointer.renderable(std.math.maxInt(u16), mouse_position)) |pointer_renderable| {
        try renderer.addToRenderQueue(pointer_renderable);
    }
}
