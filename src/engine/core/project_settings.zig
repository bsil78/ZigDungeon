const maths = @import("../maths/maths.zig");
const Vector2 = maths.Vector.Vector2;
const Rect = maths.Rect;

pub const target_fps = 60;
pub const window_size = Vector2(u32).init(960, 540);
pub const window_rect = Rect(f32).initV(Vector2(f32).Zero(), window_size.floatFromInt(f32));

pub const game_name = "Zig Dungeon";
    