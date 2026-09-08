// #region Namespace imports
const std = @import("std");
const engine = @import("engine/engine.zig");
const game = @import("game/game.zig");
const setup = @import("game/setup.zig");

pub const project_settings = @import("game/project_settings.zig");

// #endregion

// main function: entry point of the program
// It initializes the game engine, creates the game world, and runs the main game loop.
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    try engine.init(arena.allocator());
    defer engine.deinit();

    while (true) {
        var world = try setup.createWorld(arena.allocator());
        errdefer world.deinit();

        const restart_game = try game.run(&world);
        world.deinit();

        if (!restart_game) break;
    }
}
