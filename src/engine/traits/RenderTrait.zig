const std = @import("std");
const core = @import("../core/core.zig");
const events = @import("../events/events.zig");
const maths = @import("../maths/maths.zig");
const Color = @import("../color/Color.zig");
const raylib = core.raylib;
const callbacks = events.callbacks;
const globals = core.globals;
const Transform = maths.Transform;
const renderer = core.renderer;
const Allocator = std.mem.Allocator;
const RenderTrait = @This();

ptr: *anyopaque,
render: *const fn (ptr: *anyopaque) anyerror!void,
z_layer: i16,
allocator: Allocator,
tint: raylib.Color = Color.white.toRaylib(),

pub fn autoInit(allocator: Allocator, ptr: anytype, z_layer: i16) !*RenderTrait {
    return init(allocator, ptr, z_layer, Color.white);
}

pub fn init(allocator: Allocator, ptr: anytype, z_layer: i16, tint: Color) !*RenderTrait {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);
    const trait_ptr = try allocator.create(RenderTrait);

    const gen = struct {
        pub fn render(pointer: *anyopaque) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.render(self);
        }
    };

    trait_ptr.* = .{
        .ptr = ptr,
        .render = gen.render,
        .z_layer = z_layer,
        .allocator = allocator,
        .tint = tint.toRaylib(),
    };

    try renderer.addToRenderQueue(trait_ptr);
    return trait_ptr;
}

pub fn deinit(self: *RenderTrait) !void {
    try renderer.removeFromRenderQueue(self);
}
