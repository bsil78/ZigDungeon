const std = @import("std");
const core = @import("../core/core.zig");
const events = @import("../events/events.zig");
const maths = @import("../maths/maths.zig");
const callbacks = events.callbacks;
const globals = core.globals;
const Transform = maths.Transform;
const RenderTrait = @This();

ptr: *anyopaque,
layer_id: u16,
transform: *Transform,
render: *const fn (ptr: *anyopaque) anyerror!void,

fn init(ptr: anytype, layer_id: u16, transform: *Transform) RenderTrait {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn render(pointer: *anyopaque) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.process(self);
        }
    };

    const progress_callback = callbacks.CallbackType{ .callback_procedure = .CallbackProcedure.init(gen.process) };
    globals.event_emitter.subscribe(globals.GlobalEvents.process, progress_callback);

    return .{
        .ptr = ptr,
        .render = gen.render,
        .layer_id = layer_id,
        .transform = transform,
    };
}

fn deinit() !void {}
