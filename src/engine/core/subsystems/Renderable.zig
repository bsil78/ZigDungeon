// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const geometry = libs.maths.geometry;
const trigo = @import("../../../libs/maths/geometry/trigo.zig");
const raylib = @import("../../vendors/vendors.zig").raylib;
const rlh = @import("../../vendors/vendors.zig").raylib_helper;
// #endregion

// #region Concrete imports
const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Transform = @import("Transform.zig").Transform;
const Color = libs.gfx.Color;
// #endregion

pub fn Renderable(comptime MAX_CONTEXT_SIZE: usize) type {
    return struct {
        renderingFn: *const fn (*anyopaque) void,
        renderingCtx: [MAX_CONTEXT_SIZE]u8 = undefined,
        z_layer: i16 = 0,

        pub const DrawTextureContext = struct {
            texture: raylib.Texture2D,
            source: ?Rect(f32) = null,
            transform: Transform = .{},
            tint: Color = Color.WHITE,
        };

        pub fn drawTexture(ctx: *anyopaque) void {
            const dtc: DrawTextureContext = restoreContext(DrawTextureContext, ctx);
            const source = dtc.source orelse Rect(f32).init(
                0,
                0,
                @floatFromInt(dtc.texture.width),
                @floatFromInt(dtc.texture.height),
            );
            const size = Vector2(f32){ .x = source.w, .y = source.h };
            const trans = dtc.transform;
            raylib.DrawTexturePro(
                dtc.texture,
                rlh.toRaylibRectangle(source),
                rlh.toRaylibRectangle(Rect(f32).initPV(trans.position.add(trans.pivot), size.times(trans.scale))),
                rlh.toRaylibVector2(trans.pivot),
                trigo.Angles(f32).radToDeg(trans.rotation),
                rlh.toRaylibColor(dtc.tint),
            );
        }

        fn ctxCopyInternal(buffer: *[MAX_CONTEXT_SIZE]u8, ctxType: type, ctx: *const anyopaque) void {
            if (@sizeOf(ctxType) > MAX_CONTEXT_SIZE) {
                std.panic("Buffer overflow, resize MAX_CONTEXT_SIZE :\n\tcontext size is {d} but allocated buffer size is {d}", .{ @sizeOf(ctxType), MAX_CONTEXT_SIZE });
            }
            const struct_size = @sizeOf(ctxType);
            const src_ptr: *const [struct_size]u8 = @ptrCast(ctx);
            const dest_ptr: *[struct_size]u8 = @ptrCast(buffer);
            @memcpy(dest_ptr, src_ptr);
        }

        pub fn contextCopy(ctxType: type, ctx: *const anyopaque) [MAX_CONTEXT_SIZE]u8 {
            var buffer: [MAX_CONTEXT_SIZE]u8 = undefined;
            ctxCopyInternal(&buffer, ctxType, ctx);
            return buffer;
        }

        pub fn textureContext(texture: raylib.Texture2D, tranform: Transform) [MAX_CONTEXT_SIZE]u8 {
            var buffer: [MAX_CONTEXT_SIZE]u8 = undefined;
            ctxCopyInternal(&buffer, DrawTextureContext, &DrawTextureContext{ .texture = texture, .tint = Color.WHITE, .transform = tranform });
            return buffer;
        }

        pub fn textureRegionContext(texture: raylib.Texture2D, source: Rect(f32), transform: Transform) [MAX_CONTEXT_SIZE]u8 {
            var buffer: [MAX_CONTEXT_SIZE]u8 = undefined;
            ctxCopyInternal(&buffer, DrawTextureContext, &DrawTextureContext{
                .texture = texture,
                .source = source,
                .tint = Color.WHITE,
                .transform = transform,
            });
            return buffer;
        }

        pub fn restoreContext(comptime ctxType: anytype, ctx: *anyopaque) ctxType {
            var castbuffer: [@sizeOf(ctxType)]u8 align(@alignOf(ctxType)) = undefined;
            const src_bytes: *const [@sizeOf(ctxType)]u8 = @ptrCast(ctx);
            @memcpy(&castbuffer, src_bytes);
            const context: *ctxType = @ptrCast(&castbuffer);
            return context.*;
        }
    };
}
