// #region Concrete imports
const GameWorld = @import("../world/world.zig").GameWorld;
// #endregion

pub fn updateTransforms(world: *GameWorld) void {
    if (world.character) |*character| {
        character.world_transform.world = world.tilemap.transform.xform(&character.local_transform.local);
    }
    for (world.enemies.items) |*enemy| {
        enemy.world_transform.world = world.tilemap.transform.xform(&enemy.local_transform.local);
    }
}
