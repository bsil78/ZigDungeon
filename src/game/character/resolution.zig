// #region Concrete imports
const GameWorld = @import("../world/world.zig").GameWorld;
// #endregion

pub fn resolve(world: *GameWorld) void {
    if (world.character) |character| {
        if (character.health.isDead()) world.destroyCharacter();
    }
}
