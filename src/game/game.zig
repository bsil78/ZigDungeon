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
const char_input = @import("character/input.zig");
const char_res = @import("character/resolution.zig");
const npc_ai = @import("npc/generic/ai.zig");
const npc_resolution = @import("npc/generic/resolution.zig");
const clayh = libs.vendors.clay_helper;
const ui = @import("ui/ui.zig");
const game_over = ui.game_over;
const mouse_rendering = ui.mouse_rendering;
// #endregion

// #region Concrete imports
const Layers = @import("game_enums.zig").Layers;
const GameWorld = @import("world.zig").GameWorld;
const GameRenderer = types.GameRenderer;
const GameTilesSet = types.GameTilesSet;
const Color = libs.gfx.Color;
const UserSettings = core.UserSettings;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
const Assets = @import("assets/assets.zig").Assets;
const PointerConfigurations = mouse_rendering.PointerConfigurations;
const PointerConfig = mouse_rendering.PointerConfig;
// #endregion

var _world: GameWorld = undefined;
var _renderer: GameRenderer = undefined;
var _project_settings: UserSettings = undefined;
var _assets: Assets = undefined;

var _clay_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

const GameState = enum {
    RUNNING,
    GAME_OVER,
};

pub fn start() !void {
    _renderer = try startEngine();
    _assets = try Assets.init();
    defer _assets.deinit();
    defer _clay_arena.deinit();
    try clayh.initialize(_clay_arena.allocator(), _project_settings.window_rect);
    try setup_mouse();
    try doGameLoop();
}

fn startEngine() !GameRenderer {
    _project_settings = try globals.project_settings();

    const renderer = try engine.init(.{
        .target_fps = _project_settings.target_fps,
        .window_rect = _project_settings.window_rect,
        .window_size = _project_settings.window_size,
        .game_name = _project_settings.game_name,
        .random_mode = _project_settings.random_mode,
    }, globals.MAX_RENDERABLES, types.GameRenderer.RENDERABLE_CONTEXT_SIZE);
    errdefer engine.deinit();
    return renderer;
}

fn setup_mouse() !void {
    game_inputs.initializeMouse(_project_settings.window_rect);
    const pointer_sprite: engine.resources.Sprite = .{
        .texture = try _assets.mouse_pointers_spritesheet.getRegionTexture(Rect(u16).init(0, 0, 12, 16)),
    };
    try mouse_rendering.initialize(.{
        PointerConfig.static(
            pointer_sprite,
            Vector2(f32).Zero(),
            Vector2(f32).Zero(),
            @intFromEnum(Layers.MOUSE_POINTER),
        )
    });
}

fn doGameLoop() !void {
    while (true) {
        _world = try GameWorld.init(&_assets, _project_settings.window_rect);
        const restart_game = try run();
        if (!restart_game) break;
    }
}

// The run function is the main game loop that handles input, updates the game world, and renders the game state.
// It returns a boolean indicating whether the game should be restarted or not.
// The function continues to run until the window is closed or the player chooses to restart the game after a game over.
// The game loop checks player input, updates character and NPC states, resolves actions, and renders the game world.
fn run() !bool {
    var game_state = GameState.RUNNING;

    beginRun();

    defer game_inputs.releaseMouseToOS();
    errdefer _world.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.mainLoop();
        _world.newTick();
        _world.updateAnimations();

        const _inputs = game_inputs.poll();

        //std.log.info("Game state : {s}", .{@tagName(game_state)});
        switch (game_state) {
            .RUNNING => {
                const character_inputs = char_input.Inputs.fromGameInput(_inputs);
                char_input.update(&_world, &character_inputs);
                //std.log.info("World tick : {d}\n", .{_world.tick});
                try npc_ai.update(&_world);
                try npc_resolution.resolve(&_world);
                char_res.resolve(&_world);
                try prepareWorldRendering();
                // npc_resolution.clearPlans(&_world);
                if (_world.getCharacter() == null) {
                    game_state = GameState.GAME_OVER;
                }
            },
            .GAME_OVER => {
                try prepareWorldRendering();
                try _renderer.addToRenderQueue(ui.game_over.screen());
                if (_inputs.restart or game_over.restartButtonPressed()) {
                    _world.deinit();
                    return true;
                }
            },
        }
        mouse_rendering.update(pointerFromGameState(game_state));
        try _renderer.render();
        _renderer.clearRenderingQueue();
        //if(_world.tick>2) break;
    }
    _world.deinit();
    raylib.CloseWindow();
    return false;
}

fn pointerFromGameState(state: GameState) mouse_rendering.MouseVisual {
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
    const map_renderable = _world.resources.tilesMap.renderable(GameTilesSet, @constCast(&_assets.tileset.?), GameRenderer.RENDERABLE_CONTEXT_SIZE, @intFromEnum(Layers.MAP));
    try _renderer.addToRenderQueue(map_renderable);
    try queueEntities();
    if (game_inputs.mouseState().captured) {
        try mouse_rendering.addToRenderQueue(&_renderer, game_inputs.mousePosition());
    }
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
    for (&_world.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            try _renderer.addToRenderQueue(entity.renderable());
            switch (entity.data) {
                .character => {
                    try _renderer.addToRenderQueue(try ui.health_bar.characterHealthBar(entity.health, @floatFromInt(entity.visual().width()), entity.visualTransform()));
                },
                .soldier, .slime => {
                    try _renderer.addToRenderQueue(try ui.health_bar.enemyHealthBar(entity.health, @floatFromInt(entity.visual().width()), entity.visualTransform()));
                },
            }
        }
    }
}
