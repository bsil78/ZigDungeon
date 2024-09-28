const std = @import("std");
const raylib = @import("raylib.zig");
const maths = @import("../maths/maths.zig");
const Vector2 = maths.Vector2;
const Inputs = @This();

const Action = enum(u8) {
    move_right = 0x01,
    move_down = 0x02,
    move_left = 0x04,
    move_up = 0x08,
};

action: u8 = 0x00,

pub fn read() Inputs {
    var inputs = Inputs{};

    if (raylib.IsKeyPressed(raylib.KEY_UP)) inputs.action |= @intFromEnum(Action.move_up);
    if (raylib.IsKeyPressed(raylib.KEY_LEFT)) inputs.action |= @intFromEnum(Action.move_left);
    if (raylib.IsKeyPressed(raylib.KEY_DOWN)) inputs.action |= @intFromEnum(Action.move_down);
    if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) inputs.action |= @intFromEnum(Action.move_right);

    return inputs;
}

pub fn hasAction(self: Inputs) bool {
    return (self.action != 0x00);
}

pub fn isActionPressed(self: Inputs, action: Action) bool {
    return ((self.action & @intFromEnum(action)) != 0x00);
}

pub fn getDirection(self: Inputs) Vector2(f32) {
    const right: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_right)));
    const left: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_left)));
    const up: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_up)));
    const down: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_down)));

    return Vector2(f32).init(
        @floatFromInt(right - left),
        @floatFromInt(down - up),
    );
}

pub fn print(self: Inputs) void {
    inline for (@typeInfo(Action).Enum.fields) |field| {
        const action: Action = @enumFromInt(field.value);
        if (self.isActionPressed(action)) {
            std.debug.print("{s} pressed\n", .{field.name});
        }
    }
}
