// #region Namespace imports
const std = @import("std");
const libs = @import("../../../../libs/libs.zig");
const builtin = @import("builtin");
const raylib = @import("../../../vendors/vendors.zig").raylib;
const rlh = @import("../../../vendors/vendors.zig").raylib_helper; // #endregion
const plateforms = @import("../../../vendors/vendors.zig").platforms; // #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
// #endregion

pub const Mouse = @This();

pub const BUTTON_COUNT: usize = 7;
pub const DRAG_THRESHOLD: f32 = 4;
pub const DOUBLE_CLICK_INTERVAL: f32 = 0.3;

pub const Button = enum(u8) {
    left = raylib.MOUSE_BUTTON_LEFT,
    right = raylib.MOUSE_BUTTON_RIGHT,
    middle = raylib.MOUSE_BUTTON_MIDDLE,
    side = raylib.MOUSE_BUTTON_SIDE,
    extra = raylib.MOUSE_BUTTON_EXTRA,
    forward = raylib.MOUSE_BUTTON_FORWARD,
    back = raylib.MOUSE_BUTTON_BACK,
};

pub const ButtonState = struct {
    pressed: bool = false,
    double_clicked: bool = false,
    down: bool = false,
    released: bool = false,
    up: bool = true,
    dragging: bool = false,
    dropped: bool = false,
    drag_origin: Vector2(f32) = Vector2(f32).Zero(),
    drop_origin: Vector2(f32) = Vector2(f32).Zero(),
    drop_position: Vector2(f32) = Vector2(f32).Zero(),
};

pub const MouseState = struct {
    position: Vector2(f32) = Vector2(f32).Zero(),
    delta: Vector2(f32) = Vector2(f32).Zero(),
    wheel: Vector2(f32) = Vector2(f32).Zero(),
    buttons: [BUTTON_COUNT]ButtonState = @splat(.{}),
    double_click_timers: [BUTTON_COUNT]f32 = @splat(0),
    captured: bool = false,
    capture_armed: bool = true,
    has_previous_position: bool = false,
    inside_viewport: bool = false,
    entered_viewport: bool = false,
    left_viewport: bool = false,

    pub fn isButtonPressed(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].pressed;
    }

    pub fn buttonState(self: *const MouseState, button: Button) ButtonState {
        return self.buttons[@intFromEnum(button)];
    }

    pub fn isButtonDown(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].down;
    }

    pub fn isButtonReleased(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].released;
    }

    pub fn isButtonUp(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].up;
    }

    pub fn isDragging(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].dragging;
    }

    pub fn wasDropped(self: *const MouseState, button: Button) bool {
        return self.buttons[@intFromEnum(button)].dropped;
    }
};

state: MouseState = .{},

pub fn update(self: *Mouse, viewport: Rect(f32), delta_seconds: f32) void {
    const mouse_position_in_window = getMousePositionInGameWindow(f32) orelse {
        std.log.err("Failed to read mouse position in the window client area", .{});
        return;
    };
    const viewport_position = Vector2(f32).init(viewport.x, viewport.y);
    const local_viewport = Rect(f32).init(0, 0, viewport.w, viewport.h);

    self.state.delta = Vector2(f32).Zero();
    self.state.wheel = rlh.vectorFromRaylib(raylib.GetMouseWheelMoveV());

    const previous_position = self.state.position;
    self.state.position = mouse_position_in_window.minus(viewport_position);
    self.state.delta = if (self.state.has_previous_position) self.state.position.minus(previous_position) else Vector2(f32).Zero();

    const was_inside_viewport = self.state.inside_viewport;
    self.state.inside_viewport = local_viewport.containsPoint(self.state.position);
    self.state.entered_viewport = self.state.inside_viewport and !was_inside_viewport;
    self.state.left_viewport = !self.state.inside_viewport and was_inside_viewport;

    if (!self.state.inside_viewport) {
        self.releaseCursor();
        self.state.capture_armed = true;
    } else if (self.state.capture_armed) {
        self.captureCursor();
        self.state.capture_armed = false;
    }

    self.state.has_previous_position = true;
    self.updateButtons(delta_seconds);
}

pub fn releaseToOS(self: *Mouse) void {
    self.state.capture_armed = false;
    self.releaseCursor();
}

pub fn requestCapture(self: *Mouse) void {
    self.state.capture_armed = true;
}

fn updateButtons(self: *Mouse, delta_seconds: f32) void {
    inline for (std.meta.tags(Button)) |button| {
        const index = @intFromEnum(button);
        const previous = self.state.buttons[index];
        const pressed = raylib.IsMouseButtonPressed(index);
        const down = raylib.IsMouseButtonDown(index);
        const released = raylib.IsMouseButtonReleased(index);
        const elapsed = if (std.math.isFinite(delta_seconds)) @max(delta_seconds, 0) else 0;
        self.state.double_click_timers[index] = @max(self.state.double_click_timers[index] - elapsed, 0);
        const double_clicked = pressed and self.state.double_click_timers[index] > 0;
        if (pressed) {
            self.state.double_click_timers[index] = if (double_clicked) 0 else DOUBLE_CLICK_INTERVAL;
        }
        var new_buttons_state = ButtonState{
            .pressed = pressed,
            .double_clicked = double_clicked,
            .down = down,
            .released = released,
            .up = !down,
            .drag_origin = previous.drag_origin,
            .drop_origin = previous.drop_origin,
            .drop_position = previous.drop_position,
        };

        if (pressed) new_buttons_state.drag_origin = self.state.position;
        if (down) {
            new_buttons_state.dragging = previous.dragging or self.state.position.squaredDistanceTo(new_buttons_state.drag_origin) >= DRAG_THRESHOLD * DRAG_THRESHOLD;
        }
        if (released and previous.dragging) {
            new_buttons_state.dropped = true;
            new_buttons_state.drop_origin = previous.drag_origin;
            new_buttons_state.drop_position = self.state.position;
        }

        self.state.buttons[index] = new_buttons_state;
    }
}

fn captureCursor(self: *Mouse) void {
    if (self.state.captured) return;
    self.state.captured = true;
    raylib.HideCursor();
}

fn releaseCursor(self: *Mouse) void {
    if (!self.state.captured) return;
    raylib.ShowCursor();
    self.state.captured = false;
}

fn getMousePositionInGameWindow(comptime T: type) ?Vector2(T) {
    switch(comptime builtin.os.tag){
        .windows =>  {
            var point: plateforms.Windows.TYPES.WindowsPoint = undefined;
            if (plateforms.Windows.API.GetCursorPos(&point) == 0) return null;
            if (plateforms.Windows.API.ScreenToClient(raylib.GetWindowHandle(), &point) == 0) return null;
            return .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) };
        },
        .linux =>  {
            return rlh.vectorFromRaylib(raylib.GetMousePosition());
        },
        else => {
            std.log.err("Mouse position retrieval not implemented for this platform", .{});
            return null;
        }
    }
}
