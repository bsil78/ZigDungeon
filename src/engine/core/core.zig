pub const Inputs = @import("subsystems/inputs.zig");
pub const project_settings = @import("subsystems/project_settings.zig");
pub const renderer = @import("subsystems/renderer.zig");
pub const GameTimer = @import("subsystems/gametimer.zig").GameTimer;

const raylib_binding = @import("../vendors/raylib.zig");
pub const raylib = raylib_binding.raylib;
pub const ToRaylib = raylib_binding.ToRaylib;

pub const EntityID = u32;
pub const NULL_ENTITY = @import("std").math.maxInt(EntityID);