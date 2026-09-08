// #region Concrete imports
const GameWorld = @import("../world/world.zig").GameWorld;
// #endregion

pub fn resolve(world: *GameWorld) void {
    var index: usize = 0;
    while (index < world.enemies.items.len) {
        const enemy = &world.enemies.items[index];

        if (enemy.action_plan) |plan| {
            if (world.character) |*character| {
                if (plan.target.equal(&character.position.cell)) {
                    character.health.takeDamage(enemy.force);
                    enemy.action_plan = null;
                } else if (!world.isCellOccupiedByOtherEnemy(plan.target, index)) {
                    enemy.move(plan.target);
                } else {
                    enemy.action_plan = null;
                }
            } else {
                if (!world.isCellOccupiedByOtherEnemy(plan.target, index)) {
                    enemy.move(plan.target);
                } else {
                    enemy.action_plan = null;
                }
            }
        }

        if (enemy.health.isDead()) {
            world.destroyEnemy(index);
        } else {
            index += 1;
        }
    }
}

pub fn clearPlans(world: *GameWorld) void {
    for (world.enemies.items) |*enemy| enemy.action_plan = null;
}
