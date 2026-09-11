// #region Namespace imports
const engine = @import("../engine/engine.zig");
const raylib = engine.core.raylib;
const character_input = @import("character/input.zig");
const character_resolution = @import("character/resolution.zig");
const enemy_ai = @import("enemy/ai.zig");
const enemy_resolution = @import("enemy/resolution.zig");
const movement = @import("movement/systems.zig");
const rendering = @import("rendering/systems.zig");
const project_settings = @import("project_settings.zig");
// #endregion

// #region Concrete imports
const GameWorld = @import("world/world.zig").GameWorld;
// #endregion


// Renders a "Game Over" overlay on the screen when the player loses the game. 
fn drawGameOverOverlay() void {
    const width = @as(i32, @intCast(project_settings.window_size.x));
    const height = @as(i32, @intCast(project_settings.window_size.y));
    const title = "GAME OVER";
    const restart = "Press R or Enter to restart";

    const title_size: i32 = 56;
    const subtitle_size: i32 = 24;

    const title_width = raylib.MeasureText(title, title_size);
    const restart_width = raylib.MeasureText(restart, subtitle_size);

    raylib.DrawText(title, @divTrunc(width - title_width, 2), @divTrunc(height, 2) - 40, title_size, raylib.RED);
    raylib.DrawText(restart, @divTrunc(width - restart_width, 2), @divTrunc(height, 2) + 30, subtitle_size, raylib.WHITE);
}


// The run function is the main game loop that handles input, updates the game world, and renders the game state.
// It returns a boolean indicating whether the game should be restarted or not.
// The function continues to run until the window is closed or the player chooses to restart the game after a game over.
// The game loop checks for player input, updates the character and enemy states, resolves actions, and renders the game world.
pub fn run(world: *GameWorld) !bool {
    var game_over = false;

    while (!raylib.WindowShouldClose()) {
        try engine.mainLoop();

        if (!game_over and world.character != null) {
            world.newTick();
            const inputs = engine.core.Inputs.read();
            character_input.update(world, &inputs);
            try enemy_ai.update(world);
            enemy_resolution.resolve(world);
            character_resolution.resolve(world);
        }

        if (world.character == null) {
            game_over = true;
        }

        if (!game_over) {
            movement.updateTransforms(world);
            try rendering.queueTilemap(world.tilemap);
            try rendering.queueEntities(world);
            try engine.render();
        } else {
            raylib.BeginDrawing();
            raylib.ClearBackground(raylib.BLACK);
            drawGameOverOverlay();
            raylib.EndDrawing();

            if (raylib.IsKeyPressed(raylib.KEY_R) or raylib.IsKeyPressed(raylib.KEY_ENTER)) {
                return true;
            }
        }

        rendering.clearQueue();
        if (!game_over) {
            enemy_resolution.clearPlans(world);
        }
    }

    raylib.CloseWindow();
    return false;
}
