// #region Namespace imports
const libs = @import("../../../../libs/libs.zig");
const raylib = @import("../../../vendors/vendors.zig").raylib;
// #endregion

pub const Keyboard = @This();

const KEY_COUNT = 512;
const INITIAL_REPEAT_DELAY: f32 = 0.12;
const REPEAT_INTERVAL: f32 = 0.05;

repeat_timers: [KEY_COUNT]f32 = @splat(0),

pub fn isKeyPressed(_: *const Keyboard, key: c_int) bool {
    return isValidKey(key) and raylib.IsKeyPressed(key);
}

pub fn isKeyRepeated(_: *const Keyboard, key: c_int) bool {
    return isValidKey(key) and raylib.IsKeyPressedRepeat(key);
}

pub fn isKeyPressedOrRepeated(self: *Keyboard, key: c_int) bool {
    const delta_time = raylib.GetFrameTime();
    if (!isValidKey(key)) return false;
    const timer = &self.repeat_timers[@intCast(key)];

    if (raylib.IsKeyPressed(key)) {
        timer.* = INITIAL_REPEAT_DELAY;
        return true;
    }

    if (!raylib.IsKeyDown(key)) {
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

fn isValidKey(key: c_int) bool {
    return key > 0 and key < KEY_COUNT;
}
