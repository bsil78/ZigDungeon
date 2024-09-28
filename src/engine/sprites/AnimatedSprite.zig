const std = @import("std");
const ProcessTrait = @import("ProcessTrait.zig");
const SpriteAnimations = @import("SpriteAnimations.zig");
const AnimatedSprite = @This();

process_trait: ProcessTrait = undefined,
sprite_animations: ?SpriteAnimations = null,
frame: u16,
animation_name: ?[]const u8 = null,

const AnimationError = error{
    nonExistingAnimation,
};

pub fn init() AnimatedSprite {
    var animated_sprite = AnimatedSprite{};
    animated_sprite.process_trait = ProcessTrait.init(&animated_sprite);
    return animated_sprite;
}

fn process(self: *AnimatedSprite) !void {
    if (self.animation == null or self.sprite_animations == null) {
        return;
    }

    const sprite_anim = self.sprite_animations.?;
    const anim_name = self.animation_name.?;

    if (sprite_anim.animations.get(anim_name)) |anim| {
        const interval = 1.0 / anim.fps;
        std.debug.print("frame interval {d}", .{interval});
    } else {
        return AnimationError.nonExistingAnimation;
    }
}
