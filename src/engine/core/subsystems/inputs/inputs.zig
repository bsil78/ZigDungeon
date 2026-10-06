const libs = @import("../../../../libs/libs.zig");
const Rect = libs.maths.geometry.shapes.Rect;
const raylib = @import("../../../vendors/vendors.zig").raylib;

pub const Keyboard = @import("keyboard.zig");
pub const Gamepad = @import("gamepad.zig");
pub const Mouse = @import("mouse.zig");
pub const MouseState = @import("mouse.zig").MouseState;

var keyboard: Keyboard = .{};
var gamepad: Gamepad = .{};
var mouse: Mouse = .{};



pub fn updateMouse(viewport: Rect(f32)) void {
    const delta_time = raylib.GetFrameTime();
    mouse.update(viewport, delta_time);
}

pub fn releaseMouse() void {
    mouse.releaseToOS();
}

pub fn captureMouse() void {
    mouse.requestCapture();
}

pub fn mouseState() *const MouseState {
    return &mouse.state;
}

pub fn isKeyPressed(key: c_int, repeatable: bool) bool {
    if (repeatable) {
        return keyboard.isKeyPressedOrRepeated(key);
    } else {
        return keyboard.isKeyPressed(key);
    }
}

pub fn isGamepadButtonPressed(button: c_int, repeatable: bool) bool {
    if (repeatable) {
        return gamepad.isButtonPressedOrRepeated(button);
    } else {
        return gamepad.isButtonPressed(button);
    }
}

pub fn isGamepadAxisPressed(axis: c_int, direction: f32, repeatable: bool) bool {
    if (repeatable) {
        return gamepad.isAxisPressedOrRepeated(axis, direction);
    } else {
        const movement = gamepad.axisMovement(axis) * direction;
        return movement >= Gamepad.AXIS_DEADZONE;
    }
}
