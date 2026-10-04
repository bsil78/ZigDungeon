// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
// #endregion

pub fn AnimatedSpriteConfig(comptime MAX_FRAMES: u8) type {
    comptime {
        if (MAX_FRAMES == 0) @compileError("AnimatedSpriteConfig requires at least one frame");
    }

    return struct {
        pub const Error = error{
            InvalidFrameCount,
            InvalidFramesPerSecond,
            InvalidFrameRegion,
        };

        pub const FrameRegion = Rect(f32);

        regions: [MAX_FRAMES]FrameRegion,
        frame_count: u8,
        frames_per_second: f32,
        loop: bool,

        pub fn init(
            regions: [MAX_FRAMES]FrameRegion,
            frame_count: u8,
            frames_per_second: f32,
            loop: bool,
        ) Error!@This() {
            const config = @This(){
                .regions = regions,
                .frame_count = frame_count,
                .frames_per_second = frames_per_second,
                .loop = loop,
            };
            try config.validate();
            return config;
        }

        pub fn validate(self: @This()) Error!void {
            if (self.frame_count == 0 or self.frame_count > MAX_FRAMES) return error.InvalidFrameCount;
            if (!std.math.isFinite(self.frames_per_second) or self.frames_per_second <= 0) {
                return error.InvalidFramesPerSecond;
            }

            for (self.regions[0..self.frame_count]) |region| {
                if (!std.math.isFinite(region.x) or !std.math.isFinite(region.y) or
                    !std.math.isFinite(region.w) or !std.math.isFinite(region.h) or
                    region.x < 0 or region.y < 0 or region.w <= 0 or region.h <= 0)
                {
                    return error.InvalidFrameRegion;
                }
            }
        }

        pub fn validateForTexture(self: @This(), texture_width: f32, texture_height: f32) Error!void {
            try self.validate();
            for (self.regions[0..self.frame_count]) |region| {
                if (region.x + region.w > texture_width or region.y + region.h > texture_height) {
                    return error.InvalidFrameRegion;
                }
            }
        }
    };
}
