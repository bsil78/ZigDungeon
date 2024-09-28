const std = @import("std");

pub fn radToDeg(T: type, rad: T) T {
    return rad * (180.0 / std.math.pi);
}

pub fn degToRad(T: type, deg: T) T {
    return deg * (std.math.pi / 180.0);
}
