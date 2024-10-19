const std = @import("std");
const engine = @import("../engine/engine.zig");
const ActionPreview = @import("ActionPreview.zig");
const Allocator = std.mem.Allocator;
const ActorAction = @This();

ptr: *anyopaque,
resolve: *const fn (ptr: *anyopaque) anyerror!void,

pub fn init(ptr: anytype) ActorAction {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn resolve(pointer: *anyopaque) anyerror!void {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.pointer.child.resolve(self);
        }
    };

    return .{
        .ptr = ptr,
        .resolve = gen.resolve,
    };
}
