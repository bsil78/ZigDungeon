const std = @import("std");
const Allocator = std.mem.Allocator;
const Callback = @This();

allocator: Allocator,
function: *const fn (*anyopaque) anyerror!void,
context: *anyopaque,

pub fn init(allocator: Allocator, comptime T: type, function: *const fn (*T) anyerror!void, context: T) !Callback {
    const ptr = try allocator.create(@TypeOf(context));
    ptr.* = context;
    return .{
        .allocator = allocator,
        .function = @ptrCast(function),
        .context = @ptrCast(ptr),
    };
}

pub fn call(self: *Callback) anyerror!void {
    try self.function(self.context);
}
