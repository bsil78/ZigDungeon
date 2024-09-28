const std = @import("std");
const Global = @import("Globals.zig");
const Callback = @import("Callback.zig");
const ProcessTrait = @This();

const ProcessContext = struct {
    delta: f32,
};

ptr: *anyopaque,
process: *const fn (
    ptr: *anyopaque,
) anyerror!void,

fn init(ptr: anytype) ProcessTrait {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn process(pointer: *anyopaque, ctxt: ProcessContext) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.process(self, ctxt);
        }
    };

    const progress_callback = Callback.CallbackType{ .callback_procedure = .CallbackProcedure.init(gen.process) };
    Global.event_emitter.subscribe(Global.GlobalEvents.process, progress_callback);

    return .{
        .ptr = ptr,
        .process = gen.process,
    };
}
