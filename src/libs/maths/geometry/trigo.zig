// #region Namespace imports
const std = @import("std");
// #endregion

pub fn Angles(comptime T:type) type {
    return struct {

        pub fn radToDeg(rad: T) T {
            return rad * (180.0 / std.math.pi);
        }

        pub fn degToRad( deg: T) T {
            return deg * (std.math.pi / 180.0);
        }
    };
}