const std = @import("std");
const core = @import("../core/core.zig");
const events = @import("../events/events.zig");
const callbacks = events.callbacks;
const globals = core.globals;
const Inputs = core.Inputs;
const engine_events = events.engine_events;
const InputTrait = @This();

ptr: *anyopaque,
input: *const fn (ptr: *anyopaque, inputs: *const Inputs) anyerror!void,

pub fn init(ptr: anytype) !InputTrait {
    const T = @TypeOf(ptr.*);
    const ptr_T = @TypeOf(ptr);

    const gen = struct {
        pub fn input(pointer: *anyopaque, inputs: *const Inputs) anyerror!void {
            const self: ptr_T = @ptrCast(@alignCast(pointer));
            return T.input(self, inputs);
        }
    };

    const callback = callbacks.CallbackType{
        .call_context = callbacks.CallbackCallContext.init(
            T,
            Inputs,
            T.input,
            ptr,
        ),
    };

    try engine_events.event_emitter.subscribe(.Inputs, callback);

    return .{
        .ptr = ptr,
        .input = gen.input,
    };
}
