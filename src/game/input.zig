// #region Namespace imports
const raylib = @import("../engine/vendors/vendors.zig").raylib;
// #endregion

// #region Concrete imports
const Keyboard = @import("../engine/core/subsystems/input.zig").Keyboard;
const Gamepad = @import("../engine/core/subsystems/gamepad.zig").Gamepad;
// #endregion

pub const GameInput = struct {
    move_up: bool = false,
    move_down: bool = false,
    move_left: bool = false,
    move_right: bool = false,
    shoot: bool = false,
    restart: bool = false,
};

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
