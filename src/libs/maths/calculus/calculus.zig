// #region Namespace imports
const std = @import("std");
// #endregion

pub fn lerp_u8(start: u8, end: u8, t: f32) u8 {
    const a: f32 = @floatFromInt(start);
    const b: f32 = @floatFromInt(end);
    const res: f32 = a + (b - a) * t;
    return @intFromFloat(res);
}


