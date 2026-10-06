// #region Namespace imports
const libs = @import("../../../../libs/libs.zig");
const raylib = @import("../../../vendors/vendors.zig").raylib;
// #endregion

pub const Gamepad = @This();

pub const DEFAULT_ID: c_int = 0;
pub const AXIS_DEADZONE: f32 = 0.5;

const INITIAL_REPEAT_DELAY: f32 = 0.12;
const REPEAT_INTERVAL: f32 = 0.05;
const BUTTON_COUNT = raylib.GAMEPAD_BUTTON_RIGHT_THUMB + 1;
const AXIS_COUNT = raylib.GAMEPAD_AXIS_RIGHT_TRIGGER + 1;

id: c_int = DEFAULT_ID,
button_repeat_timers: [BUTTON_COUNT]f32 = @splat(0),
axis_repeat_timers: [AXIS_COUNT][2]f32 = @splat(@splat(0)),

pub fn isAvailable(self: *const Gamepad) bool {
    return self.id >= 0 and raylib.IsGamepadAvailable(self.id);
}

pub fn isButtonPressed(self: *const Gamepad, button: c_int) bool {
    return self.isAvailable() and isValidButton(button) and
        raylib.IsGamepadButtonPressed(self.id, button);
}

pub fn isButtonDown(self: *const Gamepad, button: c_int) bool {
    return self.isAvailable() and isValidButton(button) and
        raylib.IsGamepadButtonDown(self.id, button);
}

pub fn isButtonPressedOrRepeated(self: *Gamepad, button: c_int) bool {
    if (!isValidButton(button)) return false;
    const delta_time = raylib.GetFrameTime();
    return advanceRepeat(
        &self.button_repeat_timers[@intCast(button)],
        self.isButtonDown(button),
        self.isButtonPressed(button),
        delta_time,
    );
}

pub fn axisMovement(self: *const Gamepad, axis: c_int) f32 {
    if (!self.isAvailable() or !isValidAxis(axis)) return 0;
    return raylib.GetGamepadAxisMovement(self.id, axis);
}

pub fn isAxisPressedOrRepeated(
    self: *Gamepad,
    axis: c_int,
    direction: f32,
) bool {
    if (!isValidAxis(axis) or (direction != -1 and direction != 1)) return false;

    const timer = &self.axis_repeat_timers[@intCast(axis)][if (direction > 0) 1 else 0];
    const movement = self.axisMovement(axis) * direction;
    const delta_time = raylib.GetFrameTime();
    return advanceRepeat(timer, movement >= AXIS_DEADZONE, false, delta_time);
}

fn advanceRepeat(
    timer: *f32,
    is_down: bool,
    is_pressed: bool,
    delta_time: f32,
) bool {
    if (is_pressed) {
        timer.* = INITIAL_REPEAT_DELAY;
        return true;
    }
    if (!is_down) {
        timer.* = 0;
        return false;
    }
    if (timer.* <= 0) {
        timer.* = INITIAL_REPEAT_DELAY;
        return false;
    }

    const elapsed = @max(delta_time, 0);
    if (elapsed < timer.*) {
        timer.* -= elapsed;
        return false;
    }

    const overdue = elapsed - timer.*;
    timer.* = REPEAT_INTERVAL - @mod(overdue, REPEAT_INTERVAL);
    return true;
}

fn isValidButton(button: c_int) bool {
    return button > raylib.GAMEPAD_BUTTON_UNKNOWN and button <= raylib.GAMEPAD_BUTTON_RIGHT_THUMB;
}

fn isValidAxis(axis: c_int) bool {
    return axis >= raylib.GAMEPAD_AXIS_LEFT_X and axis <= raylib.GAMEPAD_AXIS_RIGHT_TRIGGER;
}
