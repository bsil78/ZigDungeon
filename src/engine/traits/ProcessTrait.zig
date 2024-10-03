const std = @import("std");
const core = @import("../core/core.zig");
const events = @import("../events/events.zig");
const callbacks = events.callbacks;
const globals = core.globals;
const ProcessTrait = @This();

ptr: *anyopaque,
process: *const fn (ptr: *anyopaque) anyerror!void,

pub fn init(ptr: anytype) ProcessTrait {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn process(pointer: *anyopaque) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.process(self);
        }
    };

    const progress_callback = callbacks.CallbackType{ .procedure = callbacks.CallbackProcedure.init(gen.process) };
    globals.event_emitter.subscribe(globals.GlobalEvents.process, progress_callback);

    return .{
        .ptr = ptr,
        .process = gen.process,
    };
}
