// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const geometry = libs.maths.geometry;
pub const random = @import("subsystems/random.zig");
pub const rendering = @import("subsystems/rendering.zig");
pub const input = @import("subsystems/input.zig");
pub const gamepad = @import("subsystems/gamepad.zig");
// #endregion

// #region Concrete imports
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Timer = libs.time.measurement.Timer;
// #endregion

pub const EntityID = u32;
pub const NULL_ENTITY = std.math.maxInt(EntityID);

pub const UserSettings = struct {
    target_fps: u8,
    window_size: Vector2(u32),
    window_rect: Rect(u32),
    game_name: [:0]const u8,
    random_mode: random.RandomMode,
};
