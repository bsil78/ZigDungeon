// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const engine = @import("../../engine/engine.zig");
const clayh = libs.vendors.clay_helper;
const globals = @import("../globals.zig");
const game_inputs = @import("../game_inputs.zig");
// #endregion

const PointerConfigurations = mouse_rendering.PointerConfigurations;
const PointerConfig = mouse_rendering.PointerConfig;
const Assets = @import("../assets/assets.zig").Assets;
const Rect = libs.maths.geometry.shapes.Rect;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Layers = @import("../game_enums.zig").Layers;
const GameStates = @import("../game_enums.zig").GameStates;
const GameEngine = @import("../game_types.zig").GameEngine;

pub const health_bar = @import("health_bars.zig");
pub const game_menu = @import("game_menu.zig");
pub const game_over = @import("game_over.zig");
pub const pause_menu = @import("pause_menu.zig");
pub const mouse_rendering = @import("mouse_rendering.zig");

var _clay_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

pub fn init(project_settings: globals.ProjectSettings, assets: Assets) void {
    clayh.initialize(_clay_arena.allocator(), project_settings.window_rect) catch |err| std.debug.panic("Cannot initialize Clay :\n\t{any}", .{err});
    game_menu.init();
    game_over.init();
    pause_menu.init();
    setup_mouse(project_settings, assets) catch |err| std.debug.panic("Cannot setup Mouse :\n\t{any}", .{err});
}

pub fn deinit() void {
    game_inputs.releaseMouseToOS();
    _clay_arena.deinit();
}

fn setup_mouse(project_settings: globals.ProjectSettings, assets: Assets) !void {
    game_inputs.initializeMouse(project_settings.window_rect);
    const pointer_sprite: engine.resources.Sprite = .{
        .texture = try assets.mouse_pointers_spritesheet.getRegionTexture(Rect(u16).init(0, 0, 12, 16)),
    };
    try mouse_rendering.initialize(.{PointerConfig.static(
        pointer_sprite,
        Vector2(f32).Zero(),
        Vector2(f32).Zero(),
        @intFromEnum(Layers.MOUSE_POINTER),
    )});
}

pub fn mousePointerRendering(game_state: GameStates, inputs: game_inputs.GameInputs, renderer: *GameEngine.RendererInstance) GameEngine.Error!void {
    const optionalRenderable =
        mouse_rendering.getRenderable(pointerFromGameState(game_state), inputs.mouse.position) catch unreachable;
    if (optionalRenderable) |renderable| {
        renderer.addToRenderQueue(renderable) catch |err| return {
            std.log.err("When rendering mouse pointer : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        };
    }
}

fn pointerFromGameState(state: GameStates) mouse_rendering.MouseVisual {
    switch (state) {
        .GAME_MENU => return mouse_rendering.MouseVisual.arrow,
        .RUNNING => return mouse_rendering.MouseVisual.arrow,
        .GAME_OVER => return mouse_rendering.MouseVisual.arrow,
        .PAUSE_MENU => return mouse_rendering.MouseVisual.arrow,
    }
}
