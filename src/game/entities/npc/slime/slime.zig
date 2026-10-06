// #region Namespace imports
const libs = @import("../../../../libs/libs.zig");
const engine = @import("../../../../engine/engine.zig");
const resources = engine.resources;
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
const GameEngine = @import("../../../game_types.zig").GameEngine;
const NPCEntityData = @import("../generic/npc_entity_data.zig");
const Visual = @import("../../../components/visual.zig").Visual;
const Layers = @import("../../../game_enums.zig").Layers;
const SpriteSheet = resources.SpriteSheet;
const GameRandom = engine.core.random.GameRandom;
const AI = @import("../generic/ai.zig");
// #endregion

const SlimeAnimation = resources.AnimatedSprite(1, 2, GameEngine.RendererInstance.RENDERABLE_CONTEXT_SIZE);

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

    npc: NPCEntityData = .{
        .normal_speed = 0.1,
        .max_speed = 1.0,
    },
    animation: SlimeAnimation,

    pub fn init(sprite_sheet: SpriteSheet) !Slime {
        const animation = try SlimeAnimation.Animation.init(sprite_sheet.texture, try animationConfig());
        return .{ 
            .npc = .{
                
            }, 
            .animation = try SlimeAnimation.init(.{animation}, 0)
        };
    }

    pub fn update(self: *Slime) void {
        self.animation.updateAnimation();
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
