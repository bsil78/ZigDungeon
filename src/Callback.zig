const Callback = @This();

function: *const fn (context: *anyopaque) void,
context: *anyopaque,

pub fn init(T: type, function: *const fn (context: *T) void, context: *T) Callback {
    return Callback{ .function = @ptrCast(function), .context = context };
}

pub fn call(self: Callback) void {
    if (self.context == .{}) {
        self.function();
        return;
    }

    self.function(self.context);
}
