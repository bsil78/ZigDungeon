// #region Namespace imports
const std = @import("std");
const maths = @import("../../../libs/maths/maths.zig");
const raylib = @import("../../vendors/raylib.zig").raylib;
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
// #endregion

const Inputs = @This();

const Action = enum(u8) {
    move_right = 0x01,
    move_down = 0x02,
    move_left = 0x04,
    move_up = 0x08,
    shoot = 0x10,
};

action: u8 = 0x00,

pub fn read() Inputs {
    var inputs = Inputs{};

    if (raylib.IsKeyPressed(raylib.KEY_UP)) inputs.action |= @intFromEnum(Action.move_up);
    if (raylib.IsKeyPressed(raylib.KEY_LEFT)) inputs.action |= @intFromEnum(Action.move_left);
    if (raylib.IsKeyPressed(raylib.KEY_DOWN)) inputs.action |= @intFromEnum(Action.move_down);
    if (raylib.IsKeyPressed(raylib.KEY_RIGHT)) inputs.action |= @intFromEnum(Action.move_right);
    if (raylib.IsKeyPressed(raylib.KEY_S)) inputs.action |= @intFromEnum(Action.shoot);

    return inputs;
}

pub fn hasAction(self: *const Inputs) bool {
    return (self.action != 0x00);
}

pub fn isActionPressed(self: *const Inputs, action: Action) bool {
    return ((self.action & @intFromEnum(action)) != 0x00);
}

pub fn getDirection(self: *const Inputs) Vector2(f32) {
    const right: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_right)));
    const left: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_left)));
    const up: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_up)));
    const down: i4 = @intCast(@intFromBool(self.isActionPressed(Action.move_down)));

    return Vector2(f32).init(
        @floatFromInt(right - left),
        @floatFromInt(down - up),
    ).normalized();
}

pub fn print(self: *const Inputs) void {
    inline for (@typeInfo(Action).Enum.fields) |field| {
        const action: Action = @enumFromInt(field.value);
        if (self.isActionPressed(action)) {
            std.debug.print("{s} pressed\n", .{field.name});
        }
    }
}
