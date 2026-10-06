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
const clayh = libs.vendors.clay_helper;
const ui = @import("ui/ui.zig");
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
const PointerConfigurations = mouse_rendering.PointerConfigurations;
const PointerConfig = mouse_rendering.PointerConfig;
// #endregion

var _project_settings: globals.ProjectSettings = undefined;
var _game_state: GameStates = .RUNNING;
var _world: ?GameWorld = null;
var _engine: GameEngine = undefined;
var _assets: Assets = undefined;
var _exit_requested: bool = false;

var _clay_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

const GameStates = enum {
    RUNNING,
    GAME_OVER,
};

pub fn start() !void {
    _engine = try startEngine();
    _assets = try Assets.init();
    defer _assets.deinit();
    defer _clay_arena.deinit();
    try clayh.initialize(_clay_arena.allocator(), _project_settings.window_rect);
    game_over.init();
    try setup_mouse();
    defer game_inputs.releaseMouseToOS();
    try doGameLoop();
}

fn startEngine() !GameEngine {
    _project_settings = try globals.ProjectSettings.init();
    const engine_instance = try GameEngine.init(.{
        .target_fps = _project_settings.target_fps,
        .window_rect = _project_settings.window_rect,
        .window_size = _project_settings.window_size,
        .game_name = _project_settings.game_name,
        .random_mode = _project_settings.random_mode,
    });
    errdefer engine_instance.deinit();
    return engine_instance;
}

fn setup_mouse() !void {
    game_inputs.initializeMouse(_project_settings.window_rect);
    const pointer_sprite: engine.resources.Sprite = .{
        .texture = try _assets.mouse_pointers_spritesheet.getRegionTexture(Rect(u16).init(0, 0, 12, 16)),
    };
    try mouse_rendering.initialize(.{PointerConfig.static(
        pointer_sprite,
        Vector2(f32).Zero(),
        Vector2(f32).Zero(),
        @intFromEnum(Layers.MOUSE_POINTER),
    )});
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
        .RUNNING => doRunningState(_inputs, delta_time) catch |err| {
            std.log.err("on Running state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
        .GAME_OVER => doGameOverState(_inputs, delta_time) catch |err| {
            std.log.err("on Game Over state : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        },
    }
    try mousePointerRendering(_inputs);
}

fn initWorld() GameEngine.Error!void {
    _world = GameWorld.init(&_assets, _project_settings.window_rect) catch |err| {
        std.log.err("Cannot init world !\n\t{any}", .{err});
        return GameEngine.Error.GameLoopFailed;
    };
    errdefer if (_world) |world| world.deinit();
    beginRun();
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
}

fn doGameOverState(_inputs: game_inputs.GameInputs, _: f32) !void {
    var world = _world.?;
    if (_inputs.restart or game_over.restartButtonPressed()) {
        world.deinit();
        _world = null;
        _game_state = GameStates.RUNNING;
    } else {
        try prepareWorldRendering();
        try _engine.renderer.addToRenderQueue(ui.game_over.screen());
    }
}

fn mousePointerRendering(inputs: game_inputs.GameInputs) GameEngine.Error!void {
    const optionalRenderable =
        mouse_rendering.getRenderable(pointerFromGameState(_game_state), inputs.mouse.position) catch unreachable;
    if (optionalRenderable) |renderable| {
        _engine.renderer.addToRenderQueue(renderable) catch |err| return {
            std.log.err("When rendering mouse pointer : {any}", .{err});
            return GameEngine.Error.GameLoopFailed;
        };
    }
}

fn pointerFromGameState(state: GameStates) mouse_rendering.MouseVisual {
    switch (state) {
        .RUNNING => return mouse_rendering.MouseVisual.arrow,
        .GAME_OVER => return mouse_rendering.MouseVisual.arrow,
    }
}

fn beginRun() void {
    game_over.hide();
    game_inputs.reset();
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

fn gameOverScreen() !void {
    raylib.BeginDrawing();
    raylib.ClearBackground(raylib.BLACK);
    game_over.drawGameOverOverlay();
    raylib.EndDrawing();
    if (raylib.IsKeyPressed(raylib.KEY_R) or raylib.IsKeyPressed(raylib.KEY_ENTER)) {
        return true;
    }
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
