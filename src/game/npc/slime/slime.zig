// #region Namespace imports
const libs = @import("../../../libs/libs.zig");
const resources = @import("../../../engine/resources/resources.zig");
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
const GameRenderer = @import("../../game_types.zig").GameRenderer;
const NPCEntityData = @import("../generic/npc_entity_data.zig").NPCEntityData;
const Visual = @import("../../components/visual.zig").Visual;
const Layers = @import("../../game_enums.zig").Layers;
const SpriteSheet = resources.SpriteSheet;
// #endregion

const SlimeAnimation = resources.AnimatedSprite(1, 2, GameRenderer.RENDERABLE_CONTEXT_SIZE);

pub const Slime = struct {
    const SlimeAnimationConfig = resources.AnimatedSpriteConfig(2);

    fn animationConfig() SlimeAnimationConfig.Error!SlimeAnimationConfig {
        return SlimeAnimationConfig.init(
            .{
                Rect(f32).init(0, 0, 16, 16),
                Rect(f32).init(16, 0, 16, 16),
            },
            2,
            10,
            true,
        );
    }

    npc: NPCEntityData = .{},
    animation: SlimeAnimation,

    pub fn create(sprite_sheet: SpriteSheet) !Slime {
        const animation = try SlimeAnimation.Animation.init(sprite_sheet.texture, try animationConfig());
        return .{ .animation = try SlimeAnimation.init(.{animation}, 0) };
    }

    pub fn update(self: *Slime, delta_seconds: f32) void {
        self.animation.update(delta_seconds);
    }

    pub fn visual(self: *const Slime) Visual {
        const frame = self.animation.currentFrame();
        return .{
            .texture = frame.texture,
            .source = frame.source,
            .z_layer = @intFromEnum(Layers.ENEMIES),
        };
    }
};
