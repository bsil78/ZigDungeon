// #region Namespace imports
const raylib = @import("../engine/vendors/vendors.zig").raylib;
const geometry = @import("../libs/libs.zig").maths.geometry;
// #endregion

// #region Concrete imports
const Keyboard = @import("../engine/core/subsystems/input.zig").Keyboard;
const Gamepad = @import("../engine/core/subsystems/gamepad.zig").Gamepad;
const Mouse = @import("../engine/core/subsystems/mouse.zig").Mouse;
const Rect = geometry.shapes.Rect;
const Vector2 = geometry.vectors.Vector2;
// #endregion

pub const GameInput = struct {
    move_up: bool = false,
    move_down: bool = false,
    move_left: bool = false,
    move_right: bool = false,
    shoot: bool = false,
    restart: bool = false,
};

var mouse_input: Mouse = .{};
var viewport: Rect(f32) = .{ .x = 0, .y = 0, .w = 0, .h = 0 };

pub fn initializeMouse(window_rect: Rect(u32)) void {
    viewport = .{
        .x = @floatFromInt(window_rect.x),
        .y = @floatFromInt(window_rect.y),
        .w = @floatFromInt(window_rect.w),
        .h = @floatFromInt(window_rect.h),
    };
}

pub fn beginMouseRun() void {
    mouse_input.releaseToOS();
    mouse_input = .{};
}

pub fn updateMouse(delta_time: f32) void {
    mouse_input.update(viewport, delta_time);
}

pub fn mouseState() *const Mouse {
    return &mouse_input;
}

pub fn mousePosition() Vector2(f32) {
    return mouse_input.position;
}

pub fn mouseHotSpotPosition() Vector2(f32) {
    return mouse_input.position.add(Vector2(f32).init(viewport.x, viewport.y));
}

pub fn releaseMouseToOS() void {
    mouse_input.releaseToOS();
}

pub fn requestMouseCapture() void {
    mouse_input.requestCapture();
}

pub fn read(
    keyboard: *Keyboard,
    gamepad: *Gamepad,
    delta_time: f32,
) GameInput {
    var inputs = GameInput{
        .move_up = keyboard.isKeyPressedOrRepeated(raylib.KEY_UP, delta_time),
        .move_down = keyboard.isKeyPressedOrRepeated(raylib.KEY_DOWN, delta_time),
        .move_left = keyboard.isKeyPressedOrRepeated(raylib.KEY_LEFT, delta_time),
        .move_right = keyboard.isKeyPressedOrRepeated(raylib.KEY_RIGHT, delta_time),
        .shoot = keyboard.isKeyRepeated(raylib.KEY_S),
        .restart = keyboard.isKeyPressed(raylib.KEY_R) or keyboard.isKeyPressed(raylib.KEY_ENTER),
    };

    const dpad_up = gamepad.isButtonPressedOrRepeated(raylib.GAMEPAD_BUTTON_LEFT_FACE_UP, delta_time);
    const dpad_down = gamepad.isButtonPressedOrRepeated(raylib.GAMEPAD_BUTTON_LEFT_FACE_DOWN, delta_time);
    const dpad_left = gamepad.isButtonPressedOrRepeated(raylib.GAMEPAD_BUTTON_LEFT_FACE_LEFT, delta_time);
    const dpad_right = gamepad.isButtonPressedOrRepeated(raylib.GAMEPAD_BUTTON_LEFT_FACE_RIGHT, delta_time);
    const stick_up = gamepad.isAxisPressedOrRepeated(raylib.GAMEPAD_AXIS_LEFT_Y, -1, delta_time);
    const stick_down = gamepad.isAxisPressedOrRepeated(raylib.GAMEPAD_AXIS_LEFT_Y, 1, delta_time);
    const stick_left = gamepad.isAxisPressedOrRepeated(raylib.GAMEPAD_AXIS_LEFT_X, -1, delta_time);
    const stick_right = gamepad.isAxisPressedOrRepeated(raylib.GAMEPAD_AXIS_LEFT_X, 1, delta_time);
    const gamepad_shoot = gamepad.isButtonPressedOrRepeated(raylib.GAMEPAD_BUTTON_RIGHT_FACE_DOWN, delta_time);
    const gamepad_restart = gamepad.isButtonPressed(raylib.GAMEPAD_BUTTON_MIDDLE_RIGHT);

    inputs.move_up = inputs.move_up or dpad_up or stick_up;
    inputs.move_down = inputs.move_down or dpad_down or stick_down;
    inputs.move_left = inputs.move_left or dpad_left or stick_left;
    inputs.move_right = inputs.move_right or dpad_right or stick_right;
    inputs.shoot = inputs.shoot or gamepad_shoot;
    inputs.restart = inputs.restart or gamepad_restart;

    return inputs;
}
