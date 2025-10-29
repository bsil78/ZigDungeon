const std = @import("std");
pub const callbacks = @import("callbacks.zig");
pub const engine_events = @import("engine_events.zig");
const CallbackType = @import("callbacks.zig").CallbackType;
const Self = @This();

const Allocator = std.mem.Allocator;
const HashMap = std.AutoHashMap;
const CallbacksArrayList = std.ArrayList(CallbackType);

pub fn EventEmitter(EventEnum: type) type {
    return struct {
        const This = @This();
        listeners: Listeners(EventEnum),
        allocator: Allocator,

        fn Listeners(EnumType: type) type {
            return HashMap(@typeInfo(EnumType).@"enum".tag_type, CallbacksArrayList);
        }

        pub fn init(allocator: Allocator) !EventEmitter(EventEnum){
            var emitter:EventEmitter(EventEnum) = .{
                .listeners = Listeners(EventEnum).init(allocator),
                .allocator = allocator
            };

            inline for (@typeInfo(EventEnum).@"enum".fields) |field|{
                const arrayList = try CallbacksArrayList.initCapacity(allocator, 4);
                try emitter.listeners.put(field.value,arrayList);
            }

            return emitter;
        }

        pub fn subscribe(self: *This, event: EventEnum, callback: CallbackType) !void {
            var callbacks_array = self.getCallbacksArray(event).?;
            callbacks_array.appendAssumeCapacity(callback);
        }

        pub fn unsubscribe(self: *This, event: EventEnum, callback: CallbackType) !void {
            var callbacks_array = self.getCallbacksArray(event).?;

            for (callbacks_array.items, 0..) |item, i| {
                if (item == callback) {
                    try callbacks_array.orderedRemove(i);
                    break;
                }
            }
        }

        pub fn emit(self: *This, event: EventEnum) !void {
            const callbacks_array = self.getCallbacksArray(event).?;

            for (callbacks_array.items) |callback_type| {
                switch (callback_type) {
                    .sub_context => |callback| try callback.call(),
                    .procedure => |callback| try callback.call(),
                    .call_context => unreachable,
                }
            }
        }

        pub fn emitWithContext(self: *This, event: EventEnum, context: anytype) !void {
            const callbacks_array = self.getCallbacksArray(event).?;

            for (callbacks_array.items) |callback_type| {
                switch (callback_type) {
                    .call_context => |callback| try callback.call(context),
                    .sub_context, .procedure => unreachable,
                }
            }
        }

        fn getCallbacksArray(self: *This, event: EventEnum) ?*CallbacksArrayList {
            const key = @intFromEnum(event);
            return self.listeners.getPtr(key);
        }
    };
}
