// #region Namespace imports
const std = @import("std");
const world_module = @import("world/world.zig");
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const GameWorld = world_module.GameWorld;
// #endregion


// Initializes the game world and its components
pub fn createWorld(allocator: Allocator) !GameWorld {
    var world = try GameWorld.init(allocator);
    errdefer world.deinit();
    return world;
}
