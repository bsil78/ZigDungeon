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
    move_up: bool = false,
    move_down: bool = false,
    move_left: bool = false,
    move_right: bool = false,
    shoot: bool = false,
    restart: bool = false,
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

pub fn reset() void {
    inputs.releaseMouse();
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
    const gamepad_restart = inputs.isGamepadButtonPressed(raylib.GAMEPAD_BUTTON_MIDDLE_RIGHT, false);

    // Keyboard inputs
    const keyboard_restart = inputs.isKeyPressed(raylib.KEY_R, false) or inputs.isKeyPressed(raylib.KEY_ENTER, false);
    const keyboard_shoot = inputs.isKeyPressed(raylib.KEY_S, true);
    const keyboard_move_up = inputs.isKeyPressed(raylib.KEY_UP, true);
    const keyboard_move_down = inputs.isKeyPressed(raylib.KEY_DOWN, true);
    const keyboard_move_left = inputs.isKeyPressed(raylib.KEY_LEFT, true);
    const keyboard_move_right = inputs.isKeyPressed(raylib.KEY_RIGHT, true);
    
    return GameInputs{
        .move_up = keyboard_move_up or dpad_up or stick_up,
        .move_down = keyboard_move_down or dpad_down or stick_down,
        .move_left = keyboard_move_left or dpad_left or stick_left,
        .move_right = keyboard_move_right or dpad_right or stick_right,
        .shoot = keyboard_shoot or gamepad_shoot,
        .restart = keyboard_restart or gamepad_restart,
        .mouse = inputs.mouseState(),
    };
}
