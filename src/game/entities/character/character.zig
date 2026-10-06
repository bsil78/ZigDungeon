// #region Namespace imports
const engine = @import("../../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Sprite = engine.resources.Sprite;
const Visual = @import("../../components/visual.zig").Visual;
const Layers = @import("../../game_enums.zig").Layers;
// #endregion

// Represents the player character in the game world,
// with properties for position, health, force, and rendering.
pub const Character = struct {
    sprite: Sprite,

    pub fn init(sprite: Sprite) Character {
        return .{ .sprite = sprite };
    }

    pub fn visual(self: *const Character) Visual {
        return .{
            .texture = self.sprite.texture,
            .z_layer = @intFromEnum(Layers.CHARACTER),
        };
    }
};
