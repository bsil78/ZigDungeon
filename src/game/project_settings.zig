// #region Namespace imports
const maths = @import("../libs/maths/maths.zig");
const random = @import("../engine/core/random.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
// #endregion

// The project_settings module contains global configuration settings for the game, such as target FPS, window size, and game name.
// It also includes a random number generator configuration for consistent behavior across different runs of the game.

pub const target_fps = 60;
pub const window_size = Vector2(u32).init(960, 540);
pub const window_rect = Rect(u32).initV(Vector2(u32).Zero(), window_size);

pub const game_name = "Zig Dungeon";
pub const random_config = random.Config{
	.mode = .live,
	.seed = 0,
};
    