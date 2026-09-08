// #region Namespace imports
const std = @import("std");
pub const vectors = @import("vector.zig");
pub const shapes = @import("shapes.zig");
// #endregion

// #region Concrete imports
pub const Transform = @import("Transform.zig");
// #endregion

pub fn Trigo(comptime T:type) type {
    return struct {

        pub fn radToDeg(rad: *const T) T {
            return rad.* * (180.0 / std.math.pi);
        }

        pub fn degToRad( deg: *const T) T {
            return deg.* * (std.math.pi / 180.0);
        }
    };
}