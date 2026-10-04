// #region Namespace imports
const std = @import("std");
const engine = @import("../engine/engine.zig");
const core = @import("../engine/core/core.zig");
const raylib = @import("../engine/vendors/vendors.zig").raylib;
const libs = @import("../libs/libs.zig");
// from game:
const globals = @import("globals.zig");
const types = @import("game_types.zig");
const game_input = @import("input.zig");
const mouse_rendering = @import("rendering/mouse.zig");
const char_input = @import("character/input.zig");
const char_res = @import("character/resolution.zig");
const npc_ai = @import("npc/generic/ai.zig");
const npc_resolution = @import("npc/generic/resolution.zig");
const game_over = @import("ui/game_over.zig");
const ui = @import("ui/ui.zig");
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
// #endregion

var _world: GameWorld = undefined;
var _renderer: GameRenderer = undefined;
var _project_settings: UserSettings = undefined;
var _assets: Assets = undefined;

const GameState = enum {
    RUNNING,
    GAME_OVER,
};

pub fn start() !void {
    _renderer = try startEngine();
    _assets = try Assets.init();
    defer _assets.deinit();
    game_input.initializeMouse(_project_settings.window_rect);
    const pointer_sprite: engine.resources.Sprite = .{
        .texture = try _assets.mouse_pointers_spritesheet.getRegionTexture(Rect(u16).init(0, 0, 12, 16)),
    };
    try mouse_rendering.initialize(.{
        mouse_rendering.PointerConfig.static(
            pointer_sprite,
            Vector2(f32).Zero(),
            Vector2(f32).Zero(),
            @intFromEnum(Layers.MOUSE_POINTER),
        ),
        mouse_rendering.PointerConfig.static(
            pointer_sprite,
            Vector2(f32).Zero(),
            Vector2(f32).Zero(),
            @intFromEnum(Layers.MOUSE_POINTER),
        ),
    });
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
    var keyboard: core.input.Keyboard = .{};
    var gamepad: core.gamepad.Gamepad = .{};
    game_input.beginMouseRun();
    mouse_rendering.beginRun();
    defer game_input.releaseMouseToOS();
    errdefer _world.deinit();

    while (!raylib.WindowShouldClose()) {
        try engine.mainLoop();
        _world.newTick();
        const delta_time = raylib.GetFrameTime();
        const inputs = game_input.read(&keyboard, &gamepad, delta_time);
        const character_inputs = char_input.Inputs.fromGameInput(inputs);
        game_input.updateMouse(delta_time);
        const pointer_state: mouse_rendering.State = switch (game_state) {
            .RUNNING => .running,
            .GAME_OVER => .game_over,
        };
        mouse_rendering.update(pointer_state, delta_time);
        _world.updateAnimations(delta_time);
        //std.log.info("Game state : {s}", .{@tagName(game_state)});
        switch (game_state) {
            .RUNNING => {
                char_input.update(&_world, &character_inputs);
                //std.log.info("World tick : {d}\n", .{_world.tick});
                try npc_ai.update(&_world);
                try npc_resolution.resolve(&_world, delta_time);
                char_res.resolve(&_world);
                try prepareWorldRendering();
                // npc_resolution.clearPlans(&_world);
                if (_world.getCharacter() == null) {
                    game_state = GameState.GAME_OVER;
                }
            },
            .GAME_OVER => {
                try prepareWorldRendering();
                try _renderer.addToRenderQueue(ui.game_over.screen(_project_settings.window_rect));
                if (inputs.restart) {
                    _world.deinit();
                    return true;
                }
            },
        }
        try _renderer.render();
        _renderer.clearRenderingQueue();
        //if(_world.tick>2) break;
    }
    _world.deinit();
    raylib.CloseWindow();
    return false;
}

fn prepareWorldRendering() !void {
    const map_renderable = _world.resources.tilesMap.renderable(GameTilesSet, @constCast(&_assets.tileset.?), GameRenderer.RENDERABLE_CONTEXT_SIZE, @intFromEnum(Layers.MAP));
    try _renderer.addToRenderQueue(map_renderable);
    try queueEntities();
    if (game_input.mouseState().captured) {
        try mouse_rendering.addToRenderQueue(&_renderer, game_input.mousePosition());
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
