// #region Namespace imports
const std = @import("std");
const engine = @import("../engine/engine.zig");
const core = @import("../engine/core/core.zig");
const raylib = @import("../engine/vendors/vendors.zig").raylib;
const libs = @import("../libs/libs.zig");
// from game:
const globals = @import("globals.zig");
const types = @import("game_types.zig");
const game_inputs = @import("game_inputs.zig");
const character_input = @import("entities/character/input.zig");
const ai = @import("entities/npc/generic/ai.zig");
const resolution = @import("entities/resolution.zig");

const ui = @import("ui/ui.zig");
const pause_menu = ui.pause_menu;
const game_menu = ui.game_menu;
const game_over = ui.game_over;
const mouse_rendering = ui.mouse_rendering;
// #endregion

// #region Concrete imports
const Layers = @import("game_enums.zig").Layers;
const GameWorld = @import("world.zig");
const GameEngine = types.GameEngine;
const GameTilesSet = types.GameTilesSet;
const Color = libs.gfx.Color;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
const Assets = @import("assets/assets.zig").Assets;
const GameStates = @import("game_enums.zig").GameStates;

// #endregion

var _project_settings: globals.ProjectSettings = undefined;
var _game_state: GameStates = .GAME_MENU;
var _world: ?GameWorld = null;
var _engine: GameEngine = undefined;
var _assets: Assets = undefined;
var _exit_requested: bool = false;



pub fn start() !void {
    _project_settings = try globals.ProjectSettings.init();
    _engine = try startEngine(_project_settings);
    _assets = try Assets.init();
    defer _assets.deinit();

    ui.init(_project_settings, _assets);
    defer ui.deinit();

    try doGameLoop();
}

fn startEngine(project_settings: globals.ProjectSettings) !GameEngine {
    const engine_instance = try GameEngine.init(.{
        .target_fps = project_settings.target_fps,
        .window_rect = project_settings.window_rect,
        .window_size = project_settings.window_size,
        .game_name = project_settings.game_name,
        .random_mode = project_settings.random_mode,
    });
    errdefer engine_instance.deinit();
    return engine_instance;
}

fn doGameLoop() !void {
    while (!_exit_requested and !raylib.WindowShouldClose()) {
        try _engine.process(gameLoop);
    }
}

// The run function is the main game loop that handles input, updates the game world, and renders the game state.
// It returns a boolean indicating whether the game should be restarted or not.
// The function continues to run until the window is closed or the player chooses to restart the game after a game over.
// The game loop checks player input, updates character and NPC states, resolves actions, and renders the game world.
fn gameLoop(delta_time: f32) GameEngine.Error!void {
    if (_world == null) try initWorld();

    _world.?.newTick();

    const _inputs = game_inputs.poll();

    //std.log.info("Game state : {s}", .{@tagName(_game_state)});

    switch (_game_state) {
        .GAME_MENU => doMenuState(_inputs, delta_time) catch |err| {
            std.log.err("on Menu state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
        .RUNNING => doRunningState(_inputs, delta_time) catch |err| {
            std.log.err("on Running state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
        .GAME_OVER => doGameOverState(_inputs, delta_time) catch |err| {
            std.log.err("on Game Over state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
        .PAUSE_MENU => doPauseMenuState(_inputs, delta_time) catch |err| {
            std.log.err("on Pause state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
    }
    try ui.mousePointerRendering(_game_state,_inputs,&_engine.renderer);
}

fn initWorld() GameEngine.Error!void {
    _world = GameWorld.init(&_assets, _project_settings.window_rect) catch |err| {
        std.log.err("Cannot init world !\n\t{any}", .{err});
        return GameEngine.Error.GameLoopFailed;
    };
    errdefer if (_world) |world| world.deinit();
    beginRun();
}

fn doMenuState(_inputs: game_inputs.GameInputs, _: f32) !void {
    try _engine.renderer.addToRenderQueue(ui.game_menu.screen());
    if (_inputs.start_action or _inputs.shoot_action or game_menu.startButtonPressed()) {
        _game_state = GameStates.RUNNING;
        return;
    }
    if (_inputs.back_action) {
        _exit_requested = true;
    }
}

fn doRunningState(_inputs: game_inputs.GameInputs, delta_time: f32) !void {
    var world = &_world.?;
    const character_inputs = character_input.Inputs.fromGameInput(_inputs);
    character_input.update(world, &character_inputs);
    //std.log.info("World tick : {d}\n", .{world.tick});
    //std.log.info("Entity 4 before braining : {any} / {s}", .{ world.entities[4].?.readNpcData().action_plan, @tagName(world.entities[4].?.readNpcData().state) });
    try ai.update(world, &_engine.random);
    //std.log.info("Entity 4 after braining : {any} / {s}", .{ world.entities[4].?.readNpcData().action_plan, @tagName(world.entities[4].?.readNpcData().state) });
    try resolution.resolve_entities(world, delta_time, &_engine.random);
    //std.log.info("Entity 4 after resolve : {any} / {s}", .{ world.entities[4].?.readNpcData().action_plan, @tagName(world.entities[4].?.readNpcData().state) });
    try prepareWorldRendering();
    if (world.getCharacter() == null) {
        _game_state = GameStates.GAME_OVER;
    }
    if (_inputs.back_action) {
        _game_state = GameStates.PAUSE_MENU;
    }
}

fn doGameOverState(_inputs: game_inputs.GameInputs, _: f32) !void {
    var world = _world.?;
    try prepareWorldRendering();
    try _engine.renderer.addToRenderQueue(ui.game_over.screen());

    if (_inputs.start_action or _inputs.shoot_action or game_over.restartButtonPressed()) {
        world.deinit();
        _world = null;
        _game_state = GameStates.RUNNING;
        return;
    }
    if (_inputs.back_action or game_over.backToMenuButtonPressed()) {
        world.deinit();
        _world = null;
        _game_state = GameStates.GAME_MENU;
    }
}

fn doPauseMenuState(_inputs: game_inputs.GameInputs, _: f32) !void {
    var world = _world.?;
    try prepareWorldRendering();
    try _engine.renderer.addToRenderQueue(ui.pause_menu.screen());

    if (_inputs.start_action or _inputs.shoot_action or pause_menu.continueButtonPressed()) {
        _game_state = GameStates.RUNNING;
        return;
    }
    if (_inputs.back_action or pause_menu.backToMenuButtonPressed()) {
        world.deinit();
        _world = null;
        _game_state = GameStates.GAME_MENU;
    }
}



fn beginRun() void {
    game_over.hide();
    mouse_rendering.resetPointer();
}

fn prepareWorldRendering() !void {
    std.debug.assert(_world != null);
    var world = _world.?;
    world.updateAnimations();
    const map_renderable =
        world.resources.tilesMap
            .renderable(GameTilesSet, @constCast(&_assets.tileset.?), GameEngine.RendererInstance.RENDERABLE_CONTEXT_SIZE, @intFromEnum(Layers.MAP));
    try _engine.renderer.addToRenderQueue(map_renderable);
    try queueEntities();
}

pub fn queueEntities() !void {
    std.debug.assert(_world != null);
    const world = _world.?;
    for (&world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            try _engine.renderer.addToRenderQueue(entity.renderable());
            switch (entity.data) {
                .character => {
                    try _engine.renderer.addToRenderQueue(try ui.health_bar.characterHealthBar(entity.health, @floatFromInt(entity.visual().width()), entity.visualTransform()));
                },
                .soldier, .slime => {
                    try _engine.renderer.addToRenderQueue(try ui.health_bar.enemyHealthBar(entity.health, @floatFromInt(entity.visual().width()), entity.visualTransform()));
                },
            }
        }
    }
}
