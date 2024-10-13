const std = @import("std");
const testing = std.testing;
const raylib = @import("../core/raylib.zig");
const fmt = std.fmt;
const Color = @This();

const ColorError = error{InvalidHexValue};

r: u8,
g: u8,
b: u8,
a: u8,

pub const white = initRgb(255, 255, 255);
pub const transparent = init(255, 255, 255, 0);
pub const gray = initRgb(127, 127, 127);
pub const red = initRgb(255, 0, 0);
pub const green = initRgb(0, 255, 0);
pub const blue = initRgb(0, 0, 255);
pub const magenta = initRgb(255, 0, 255);
pub const cyan = initRgb(0, 255, 255);
pub const yellow = initRgb(0, 255, 255);

pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = a };
}

pub fn initRgb(r: u8, g: u8, b: u8) Color {
    return .{ .r = r, .g = g, .b = b, .a = 255 };
}

/// Init a color out of its hexadecimal code.
/// The code can take a # at its start or not without any consequence.
/// The hex code itself can be either 6 or 8 characters long, depending on if you want to precise the alpha value or not.
/// If the hex code is 6 characters long then the color will be fully opaque by default.
pub fn initHex(hex_code: []const u8) !Color {
    if (hex_code.len == 0) return ColorError.InvalidHexValue;

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

pub fn toRaylib(self: *const Color) raylib.Color {
    return raylib.Color{ .r = self.r, .g = self.g, .b = self.b, .a = self.a };
}

test initHex {
    try testing.expectEqual(try initHex("#FFFFFF"), init(255, 255, 255, 255));
    try testing.expectEqual(try initHex("#FF0000"), init(255, 0, 0, 255));
    try testing.expectEqual(try initHex("#00FF00"), init(0, 255, 0, 255));
    try testing.expectEqual(try initHex("0000FF"), init(0, 0, 255, 255));
    try testing.expectEqual(try initHex("#FFFFFF00"), init(255, 255, 255, 0));
}
