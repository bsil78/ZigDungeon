// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const raylib = libs.vendors.raylib;
// #endregion

// #region Concrete imports
const Rect = libs.maths.geometry.shapes.Rect;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Color = libs.gfx.Color;
const TypesHelper = @import("../../../libs/utils/utils.zig").TypesHelper;
// #endregion

pub const raylib_helpers = struct {
    /// Extrait une zone spécifique d'une Texture2D pour en créer une nouvelle
    pub fn extractSubTexture(source: raylib.Texture2D, region: Rect(u16)) raylib.Texture2D {
        const src_image = raylib.LoadImageFromTexture(source);
        defer raylib.UnloadImage(src_image);
        const cropped_image = raylib.ImageFromImage(src_image, toRaylibRectangle(region));
        defer raylib.UnloadImage(cropped_image);
        return raylib.LoadTextureFromImage(cropped_image);
    }

    pub fn toRaylibColor(col: Color) raylib.Color {
        return raylib.Color{ .r = col.r, .g = col.g, .b = col.b, .a = col.a };
    }

    pub fn toRaylibVector2(vec: anytype) raylib.Vector2 {
        comptime {
            const vecScalar: type = @TypeOf(vec).SCALAR;
            std.debug.assert(@TypeOf(vec) == Vector2(vecScalar));
            TypesHelper.assert(vecScalar, TypesHelper.Asserts.numeric, "Vector2 scalar must be numeric");
        }
        const v = vec.as(f32);
        return raylib.Vector2{ .x = v.x, .y = v.y };
    }

    pub fn toRaylibRectangle(rect: anytype) raylib.Rectangle {
        comptime {
            const rectScalar: type = @TypeOf(rect).SCALAR;
            if (@TypeOf(rect) != Rect(rectScalar)) {
                @panic("Rect is required to convert to raylib Rectangle");
            }

            TypesHelper.assert(rectScalar, TypesHelper.Asserts.numeric, "Rect scalar must be numeric");
        }

        return raylib.Rectangle{
            .x = @as(f32, rect.x),
            .y = @as(f32, rect.y),
            .width = @as(f32, rect.w),
            .height = @as(f32, rect.h),
        };
    }
};
