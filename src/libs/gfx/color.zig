// #region Namespace imports
const std = @import("std");
const fmt = std.fmt;
const maths = @import("../maths/maths.zig");
// #endregion

const Color = @This();

const Error = error{InvalidHexValue};

r: u8,
g: u8,
b: u8,
a: u8,

pub const BLACK = initRgb(0, 0, 0);
pub const WHITE = initRgb(255, 255, 255);
pub const TRANSPARENT = init(0, 0, 0, 0);
pub const GRAY = initRgb(127, 127, 127);
pub const RED = initRgb(255, 0, 0);
pub const GREEN = initRgb(0, 255, 0);
pub const BLUE = initRgb(0, 0, 255);
pub const MAGENTA = initRgb(255, 0, 255);
pub const CYAN = initRgb(0, 255, 255);
pub const YELLOW = initRgb(0, 255, 255);

pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

pub fn initRgb(r: u8, g: u8, b: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = 255 };
}

pub fn initHex(hex_code: []const u8) Error!Color {
    if (hex_code.len == 0) return Error.InvalidHexValue;

    const hex = if (hex_code[0] == '#') hex_code[1..] else hex_code;

    const alpha = switch (hex.len) {
        6 => 255,
        8 => try fmt.parseInt(u8, hex[6..], 16),
        else => unreachable,
    };

    return .{
        .r = try fmt.parseInt(u8, hex[0..2], 16),
        .g = try fmt.parseInt(u8, hex[2..4], 16),
        .b = try fmt.parseInt(u8, hex[4..6], 16),
        .a = alpha,
    };
}

pub fn lerp_opaque(start: Color, end: Color, ratio: f32) Color {
    return Color{
        .r = maths.calculus.lerp_u8(start.r, end.r, ratio),
        .g = maths.calculus.lerp_u8(start.g, end.g, ratio),
        .b = maths.calculus.lerp_u8(start.b, end.b, ratio),
        .a = 255,
    };
}

pub fn lerp(start: Color, end: Color, ratio: f32) Color {
    return Color{
        .r = maths.calculus.lerp_u8(start.r, end.r, ratio),
        .g = maths.calculus.lerp_u8(start.g, end.g, ratio),
        .b = maths.calculus.lerp_u8(start.b, end.b, ratio),
        .a = maths.calculus.lerp_u8(start.a, end.a, ratio),
    };
}
