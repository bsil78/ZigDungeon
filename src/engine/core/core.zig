// #region Namespace imports
const std = @import("std");
const libs = @import("../../libs/libs.zig");
const geometry = libs.maths.geometry;
// #endregion

// #region Concrete imports
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Timer = libs.time.measurement.Timer;
// #endregion

pub const inputs = @import("subsystems/inputs/inputs.zig");
pub const random = @import("subsystems/random.zig");
pub const rendering = @import("subsystems/rendering.zig");


