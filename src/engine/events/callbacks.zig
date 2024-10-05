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
    function: *const fn (*anyopaque) anyerror!void,
    receiver: *anyopaque,

    pub fn init(T: type, function: *const fn (*T) anyerror!void, receiver: *T) CallbackProcedure {
        return .{
            .function = function,
            .receiver = @ptrCast(@alignCast(receiver)),
        };
    }

    pub fn call(self: *const CallbackProcedure) anyerror!void {
        try self.function(@constCast(self.receiver));
    }
};

pub const CallbackSubscribeContext = struct {
    function: *const fn (*anyopaque, *anyopaque) anyerror!void,
    receiver: *anyopaque,
    context: *anyopaque,

    pub fn init(T: type, K: type, function: *const fn (*T, *K) anyerror!void, receiver: *T, context: *K) !CallbackSubscribeContext {
        //const ptr = try allocator.create(@TypeOf(context));
        //ptr.* = context;
        return .{
            .function = @ptrCast(function),
            .context = @ptrCast(@alignCast(context)),
            .receiver = @ptrCast(@alignCast(receiver)),
        };
    }

    //pub fn deinit(self: *CallbackSubscribeContext) !void {
    //    try self.allocator.destroy(self.context);
    //}

    pub fn call(self: *const CallbackSubscribeContext) anyerror!void {
        try self.function(@constCast(self.receiver), self.context);
    }
};

pub const CallbackCallContext = struct {
    function: *const fn (*anyopaque, *const anyopaque) anyerror!void,
    receiver: *anyopaque,

    pub fn init(T: type, K: type, function: *const fn (*T, *K) anyerror!void, receiver: *T) CallbackCallContext {
        return .{
            .function = @ptrCast(function),
            .receiver = @ptrCast(@alignCast(receiver)),
        };
    }

    pub fn call(self: *const CallbackCallContext, context: anytype) anyerror!void {
        try self.function(@constCast(self.receiver), @ptrCast(context));
    }
};
