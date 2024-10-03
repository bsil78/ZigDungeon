const std = @import("std");
const core = @import("../core/core.zig");
const events = @import("../events/events.zig");
const maths = @import("../maths/maths.zig");
const callbacks = events.callbacks;
const globals = core.globals;
const Transform = maths.Transform;
const renderer = core.renderer;
const RenderTrait = @This();

ptr: *anyopaque,
render: *const fn (ptr: *anyopaque) anyerror!void,

pub fn init(ptr: anytype) !RenderTrait {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn render(pointer: *anyopaque) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.render(self);
        }
    };

    const render_trait = .{
        .ptr = ptr,
        .render = gen.render,
    };

    return render_trait;
}

fn deinit(self: *RenderTrait) !void {
    try renderer.removeFromRenderQueue(self);
}
