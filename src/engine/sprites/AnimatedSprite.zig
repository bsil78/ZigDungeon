// #region Namespace imports
const std = @import("std");
// #endregion

// #region Concrete imports
const SpriteAnimations = @import("SpriteAnimations.zig");
// #endregion

const AnimatedSprite = @This();

sprite_animations: ?SpriteAnimations = null,
frame: u16,
animation_name: ?[]const u8 = null,

const AnimationError = error{
    nonExistingAnimation,
};

pub fn init() AnimatedSprite {
    return AnimatedSprite{
        .frame = 0,
    };
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
