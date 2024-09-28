const std = @import("std");
const CallbackType = @import("Callback.zig").CallbackType;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const Level = @import("Level.zig");
const Self = @This();

pub fn EventEmitter(EventEnum: type) type {
    return struct {
        const This = @This();
        listeners: Listeners(EventEnum),

        pub fn Listeners(EnumType: type) type {
            return HashMap(@typeInfo(EnumType).@"enum".tag_type, ArrayList(CallbackType));
        }

        pub fn init(allocator: Allocator) !This {
            var emitter = .{
                .listeners = Listeners(EventEnum).init(allocator),
            };

            inline for (@typeInfo(EventEnum).@"enum".fields) |field| {
                try emitter.listeners.put(field.value, ArrayList(CallbackType).init(allocator));
            }

            return emitter;
        }

        pub fn subscribe(self: *This, event: EventEnum, callback: CallbackType) !void {
            var callbacks_array = self.getCallbacksArray(event).?;
            try callbacks_array.append(callback);
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
            std.debug.print("emit event: {s}\n", .{@tagName(event)});
            const callbacks_array = self.getCallbacksArray(event).?;

            for (callbacks_array.items) |callback_type| {
                std.debug.print("callback called\n", .{});
                switch (callback_type) {
                    .sub_context => |callback| try callback.call(),
                    .procedure => |callback| try callback.call(),
                    .call_context => unreachable,
                }
            }
        }

        pub fn emitWithContext(self: *This, event: EventEnum, context: anytype) !void {
            std.debug.print("emit event: {s}\n", .{@tagName(event)});
            const callbacks_array = self.getCallbacksArray(event).?;

            for (callbacks_array.items) |callback_type| {
                std.debug.print("callback called\n", .{});
                switch (callback_type) {
                    .call_context => |callback| try callback.call(context),
                    .sub_context, .procedure => unreachable,
                }
            }
        }

        fn getCallbacksArray(self: *This, event: EventEnum) ?*ArrayList(CallbackType) {
            const key = @intFromEnum(event);
            return self.listeners.getPtr(key);
        }
    };
}
