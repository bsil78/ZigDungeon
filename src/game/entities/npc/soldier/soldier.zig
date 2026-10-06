// #region Namespace imports
const engine = @import("../../../../engine/engine.zig");
// #endregion

// #region Concrete imports
const Sprite = engine.resources.Sprite;
const Visual = @import("../../../components/visual.zig").Visual;
const Layers = @import("../../../game_enums.zig").Layers;
const NPCEntityData = @import("../generic/npc_entity_data.zig");
const GameRandom = engine.core.random.GameRandom;
const ai = @import("../generic/ai.zig");
// #endregion

pub const Soldier = struct {
    npc: NPCEntityData = .{},
    sprite: Sprite,

    pub fn init(sprite: Sprite) Soldier {
        return .{
            .sprite = sprite,
        };
    }

    pub fn visual(self: *const Soldier) Visual {
        return .{
            .texture = self.sprite.texture,
            .z_layer = @intFromEnum(Layers.ENEMIES),
        };
    }
};
