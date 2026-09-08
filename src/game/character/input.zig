// #region Namespace imports
const engine = @import("../../engine/engine.zig");
const combat = @import("../combat/systems.zig");
// #endregion

// #region Concrete imports
const Inputs = engine.core.Inputs;
const GameWorld = @import("../world/world.zig").GameWorld;
// #endregion

pub fn update(world: *GameWorld, inputs: *const Inputs) void {
    if (world.character) |*character| {
        if (!inputs.hasAction()) return;

        const direction = inputs.getDirection().intFromFloat(i16);
        const destination = character.position.cell.add(&direction);
        if (world.getEnemyAtCell(destination)) |enemy| {
            enemy.takeDamage(character.force);
            return;
        }

        if (world.isCellWalkable(destination)) |walkable| {
            if (walkable) character.move(destination);
        } else |_| {}
    }
}
