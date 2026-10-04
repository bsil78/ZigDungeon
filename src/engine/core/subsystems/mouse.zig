// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const raylib = libs.vendors.raylib;
const raylib_platform = libs.vendors.raylib_platform;
// #endregion

// #region Concrete imports
const Vector2 = libs.maths.geometry.vectors.Vector2;
const Rect = libs.maths.geometry.shapes.Rect;
// #endregion

pub const Mouse = struct {
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

    pub fn update(self: *Mouse, viewport: Rect(f32), delta_seconds: f32) void {
        const screen_position = raylib_platform.getMousePositionInClient() orelse {
            std.log.err("Failed to read mouse position in the window client area", .{});
            return;
        };
        const window_position = Vector2(f32).init(screen_position.x, screen_position.y);
        const viewport_position = Vector2(f32).init(viewport.x, viewport.y);
        const local_viewport = Rect(f32).init(0, 0, viewport.w, viewport.h);

        self.delta = Vector2(f32).Zero();
        self.wheel = vectorFromRaylib(raylib.GetMouseWheelMoveV());

        const previous_position = self.position;
        self.position = window_position.minus(viewport_position);
        self.delta = if (self.has_previous_position) self.position.minus(previous_position) else Vector2(f32).Zero();

        const was_inside_viewport = self.inside_viewport;
        self.inside_viewport = contains(local_viewport, self.position);
        self.entered_viewport = self.inside_viewport and !was_inside_viewport;
        self.left_viewport = !self.inside_viewport and was_inside_viewport;

        if (!self.inside_viewport) {
            self.releaseCursor();
            self.capture_armed = true;
        } else if (self.capture_armed) {
            self.captureCursor();
            self.capture_armed = false;
        }

        self.has_previous_position = true;
        self.updateButtons(delta_seconds);
    }

    pub fn releaseToOS(self: *Mouse) void {
        self.capture_armed = false;
        self.releaseCursor();
    }

    pub fn requestCapture(self: *Mouse) void {
        self.capture_armed = true;
    }

    pub fn isButtonPressed(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].pressed;
    }

    pub fn buttonState(self: *const Mouse, button: Button) ButtonState {
        return self.buttons[@intFromEnum(button)];
    }

    pub fn isButtonDown(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].down;
    }

    pub fn isButtonReleased(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].released;
    }

    pub fn isButtonUp(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].up;
    }

    pub fn isDragging(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].dragging;
    }

    pub fn wasDropped(self: *const Mouse, button: Button) bool {
        return self.buttons[@intFromEnum(button)].dropped;
    }

    fn updateButtons(self: *Mouse, delta_seconds: f32) void {
        inline for (std.meta.tags(Button)) |button| {
            const index = @intFromEnum(button);
            const previous = self.buttons[index];
            const pressed = raylib.IsMouseButtonPressed(index);
            const down = raylib.IsMouseButtonDown(index);
            const released = raylib.IsMouseButtonReleased(index);
            const elapsed = if (std.math.isFinite(delta_seconds)) @max(delta_seconds, 0) else 0;
            self.double_click_timers[index] = @max(self.double_click_timers[index] - elapsed, 0);
            const double_clicked = pressed and self.double_click_timers[index] > 0;
            if (pressed) {
                self.double_click_timers[index] = if (double_clicked) 0 else DOUBLE_CLICK_INTERVAL;
            }
            var state = ButtonState{
                .pressed = pressed,
                .double_clicked = double_clicked,
                .down = down,
                .released = released,
                .up = !down,
                .drag_origin = previous.drag_origin,
                .drop_origin = previous.drop_origin,
                .drop_position = previous.drop_position,
            };

            if (pressed) state.drag_origin = self.position;
            if (down) {
                state.dragging = previous.dragging or distanceSquared(self.position, state.drag_origin) >= DRAG_THRESHOLD * DRAG_THRESHOLD;
            }
            if (released and previous.dragging) {
                state.dropped = true;
                state.drop_origin = previous.drag_origin;
                state.drop_position = self.position;
            }

            self.buttons[index] = state;
        }
    }

    fn captureCursor(self: *Mouse) void {
        if (self.captured) return;
        self.captured = true;
        raylib.HideCursor();
    }

    fn releaseCursor(self: *Mouse) void {
        if (!self.captured) return;
        raylib.ShowCursor();
        self.captured = false;
    }

    fn vectorFromRaylib(vector: raylib.Vector2) Vector2(f32) {
        return Vector2(f32).init(vector.x, vector.y);
    }

    fn distanceSquared(left: Vector2(f32), right: Vector2(f32)) f32 {
        const delta = left.minus(right);
        return delta.x * delta.x + delta.y * delta.y;
    }

    fn contains(rect: Rect(f32), point: Vector2(f32)) bool {
        return point.x >= rect.x and point.y >= rect.y and
            point.x < rect.x + rect.w and point.y < rect.y + rect.h;
    }
};
