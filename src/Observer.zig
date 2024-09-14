const std = @import("std");
const Callback = @import("Callback.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const HashMap = std.AutoHashMap;
const Self = @This();

pub fn EventEmitter(EventEnum: type) type {
    return struct {
        const This = @This();
        listeners: Listeners(EventEnum),

        pub fn Listeners(EnumType: type) type {
            return HashMap(@typeInfo(EnumType).Enum.tag_type, ArrayList(Callback));
        }

        pub fn init(allocator: Allocator) !This {
            var emitter = .{
                .listeners = Listeners(EventEnum).init(allocator),
            };

            inline for (@typeInfo(EventEnum).Enum.fields) |field| {
                try emitter.listeners.put(field.value, ArrayList(Callback).init(allocator));
            }

            return emitter;
        }

        pub fn subscribe(self: *This, event: EventEnum, callback: Callback) !void {
            var callbacks_array = self.getCallbacksArray(event).?;
            try callbacks_array.append(callback);
        }

        pub fn unsubscribe(self: *This, event: EventEnum, callback: Callback) !void {
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

            for (callbacks_array) |callback| {
                callback.call();
            }
        }

        fn getCallbacksArray(self: *This, event: EventEnum) ?ArrayList(Callback) {
            const key = @intFromEnum(event);
            return self.listeners.get(key);
        }
    };
}
