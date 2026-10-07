// #region Namespace imports
const std = @import("std");
const engine = @import("../../engine/engine.zig");
const types = @import("../game_types.zig");
const raylib = engine.vendors.raylib;
// #endregion

// #region Concrete imports
const Vector2 = @import("../../libs/libs.zig").maths.geometry.vectors.Vector2;
const SizedRenderable = types.SizedRenderable;
// #endregion

pub const MouseVisual = enum {
    arrow,
};

pub const Pointer = engine.resources.MousePointer(
    MouseVisual,
    8,
    types.GameEngine.RendererInstance.RENDERABLE_CONTEXT_SIZE,
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


pub fn getRenderable(activeVisual: MouseVisual, mouse_position: Vector2(f32)) !?SizedRenderable {
    try pointer.setVisual(activeVisual);
    pointer.updateAnimation();
    return pointer.renderable(mouse_position);
}
