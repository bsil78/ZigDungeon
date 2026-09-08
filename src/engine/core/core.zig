// #region Namespace imports
const std = @import("std");
const raylib_binding = @import("../vendors/raylib.zig");
pub const raylib = raylib_binding.raylib;
pub const renderer = @import("subsystems/renderer.zig");
// #endregion

// #region Concrete imports
pub const Inputs = @import("subsystems/inputs.zig");
pub const GameTimer = @import("subsystems/gametimer.zig").GameTimer;
pub const random = @import("random.zig");
pub const ToRaylib = raylib_binding.ToRaylib;
// #endregion

pub const EntityID = u32;
pub const NULL_ENTITY = std.math.maxInt(EntityID);