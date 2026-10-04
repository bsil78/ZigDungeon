// #region Namespace imports
const std = @import("std");
// #endregion

// #region Concrete imports
const GameWorld = @import("../world.zig").GameWorld;
// #endregion

pub fn resolve(world: *GameWorld) void {
    if (world.getCharacter()) |character| {
        if (character.health.isDead()) {
            //std.log.info("Player character is dead",.{});
            world.destroyCharacter();
        }
    }
}
