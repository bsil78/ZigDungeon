// #region Concrete imports
const Character = @import("../character/character.zig").Character;
const Enemy = @import("../enemy/enemy.zig").Enemy;
// #endregion

pub fn damageCharacter(character: *Character, amount: u16) void {
    character.health.takeDamage(amount);
}

pub fn attackEnemy(character: *Character, enemy: *Enemy) void {
    enemy.health.takeDamage(character.force);
}
