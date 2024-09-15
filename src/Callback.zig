const Callback = @This();

function: Function(*anyopaque),
context: *anyopaque,

pub fn Function(ArgType: type, ReturnType: type) type {
    return *const fn (context: ArgType) ReturnType;
}

pub fn init(ArgType: type, function: Function(*ArgType), context: *ArgType) Callback {
    return Callback{ .function = @ptrCast(function), .context = context };
}

pub fn initVoid(function: Function(void)) Callback {
    return Callback{ .function = @ptrCast(function), .context = {} };
}

pub fn call(self: Callback) void {
    const context_type = @TypeOf(self.context);

    self.function(self.context);
}
