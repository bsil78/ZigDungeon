const std = @import("std");
const Allocator = std.mem.Allocator;

const CallbackTypeTag = enum {
    procedure,
    sub_context,
    call_context,
};

pub const CallbackType = union(CallbackTypeTag) {
    procedure: CallbackProcedure,
    sub_context: CallbackSubscribeContext,
    call_context: CallbackCallContext,
};

pub const CallbackProcedure = struct {
    function: *const fn () anyerror!void,

    pub fn init(function: *const fn () anyerror!void) CallbackProcedure {
        return .{ .function = function };
    }

    pub fn call(self: *const CallbackProcedure) anyerror!void {
        try self.function();
    }
};

pub const CallbackSubscribeContext = struct {
    allocator: Allocator,
    function: *const fn (*anyopaque) anyerror!void,
    context: *anyopaque,

    pub fn init(allocator: Allocator, comptime T: type, function: *const fn (*T) anyerror!void, context: T) !CallbackSubscribeContext {
        const ptr = try allocator.create(@TypeOf(context));
        ptr.* = context;
        return .{
            .allocator = allocator,
            .function = @ptrCast(function),
            .context = @ptrCast(ptr),
        };
    }

    pub fn deinit(self: *CallbackSubscribeContext) !void {
        try self.allocator.destroy(self.context);
    }

    pub fn call(self: *const CallbackSubscribeContext) anyerror!void {
        try self.function(self.context);
    }
};

pub const CallbackCallContext = struct {
    function: *const fn (*anyopaque) anyerror!void,

    pub fn init(T: type, function: *const fn (T) anyerror!void) CallbackProcedure {
        return .{ .function = function };
    }

    pub fn call(self: *const CallbackCallContext, context: anytype) anyerror!void {
        try self.function(@constCast(context));
    }
};
