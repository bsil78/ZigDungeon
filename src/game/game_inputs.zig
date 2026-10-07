// #region Namespace imports
const raylib = @import("../engine/vendors/vendors.zig").raylib;
const geometry = @import("../libs/libs.zig").maths.geometry;
const engine = @import("../engine/engine.zig");

// #endregion

// #region Concrete imports
const inputs = engine.core.inputs;
const Rect = geometry.shapes.Rect;
const Vector2 = geometry.vectors.Vector2;
// #endregion

pub const GameInputs = struct {
    move_up_action: bool = false,
    move_down_action: bool = false,
    move_left_action: bool = false,
    move_right_action: bool = false,
    shoot_action: bool = false,
    start_action: bool = false,
    back_action: bool = false,
    mouse: *const inputs.MouseState = undefined,
};

var viewport: Rect(f32) = .{ .x = 0, .y = 0, .w = 0, .h = 0 };

pub fn initializeMouse(window_rect: Rect(u32)) void {
    viewport = .{
        .x = @floatFromInt(window_rect.x),
        .y = @floatFromInt(window_rect.y),
        .w = @floatFromInt(window_rect.w),
        .h = @floatFromInt(window_rect.h),
    };
}

pub fn mouseState() *const inputs.MouseState {
    return inputs.mouseState();
}

pub fn mouseGamePosition() Vector2(f32) {
    return inputs.mouseState().position.add(Vector2(f32).init(viewport.x, viewport.y));
}

pub fn releaseMouseToOS() void {
    inputs.releaseMouse();
}

pub fn poll() GameInputs {
    inputs.poll(viewport);

    // Gamepad inputs
    const dpad_up = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_LEFT_FACE_UP, true);
    const dpad_down = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_LEFT_FACE_DOWN, true);
    const dpad_left = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_LEFT_FACE_LEFT, true);
    const dpad_right = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_LEFT_FACE_RIGHT, true);
    const stick_up = inputs.isGamepadAxisPressed(raylib.GAMEPAD_AXIS_LEFT_Y, -1, true);
    const stick_down = inputs.isGamepadAxisPressed(raylib.GAMEPAD_AXIS_LEFT_Y, 1, true);
    const stick_left = inputs.isGamepadAxisPressed(raylib.GAMEPAD_AXIS_LEFT_X, -1, true);
    const stick_right = inputs.isGamepadAxisPressed(raylib.GAMEPAD_AXIS_LEFT_X, 1, true);
    const gamepad_shoot = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_RIGHT_FACE_DOWN, false);
    const gamepad_start = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_MIDDLE_RIGHT, false);
    const gamepad_back = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_MIDDLE_LEFT, false);

    // Keyboard inputs
    const keyboard_start = inputs.isKeyPressed(raylib.KEY_R, false) or inputs.isKeyPressed(raylib.KEY_ENTER, false);
    const keyboard_shoot = inputs.isKeyPressed(raylib.KEY_S, true);
    const keyboard_back = inputs.isKeyPressed(raylib.KEY_ESCAPE, false) or inputs.isKeyPressed(raylib.KEY_BACKSPACE, false);
    const keyboard_move_up = inputs.isKeyPressed(raylib.KEY_UP, true);
    const keyboard_move_down = inputs.isKeyPressed(raylib.KEY_DOWN, true);
    const keyboard_move_left = inputs.isKeyPressed(raylib.KEY_LEFT, true);
    const keyboard_move_right = inputs.isKeyPressed(raylib.KEY_RIGHT, true);

    return GameInputs{
        .move_up_action = keyboard_move_up or dpad_up or stick_up,
        .move_down_action = keyboard_move_down or dpad_down or stick_down,
        .move_left_action = keyboard_move_left or dpad_left or stick_left,
        .move_right_action = keyboard_move_right or dpad_right or stick_right,
        .shoot_action = keyboard_shoot or gamepad_shoot,
        .start_action = keyboard_start or gamepad_start,
        .back_action = keyboard_back or gamepad_back,
        .mouse = inputs.mouseState(),
    };
}
