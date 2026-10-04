const builtin = @import("builtin");

pub const raylib_bindings = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

pub const platform = struct {
    const WindowsPoint = extern struct {
        x: i32,
        y: i32,
    };

    const windows = if (builtin.os.tag == .windows) struct {
        extern "user32" fn GetCursorPos(point: *WindowsPoint) callconv(.winapi) i32;
        extern "user32" fn ScreenToClient(window: ?*anyopaque, point: *WindowsPoint) callconv(.winapi) i32;
    } else struct {};

    pub fn getMousePositionInClient() ?raylib_bindings.Vector2 {
        if (comptime builtin.os.tag == .windows) {
            var point: WindowsPoint = undefined;
            if (windows.GetCursorPos(&point) == 0) return null;
            if (windows.ScreenToClient(raylib_bindings.GetWindowHandle(), &point) == 0) return null;
            return .{ .x = @floatFromInt(point.x), .y = @floatFromInt(point.y) };
        }
        return raylib_bindings.GetMousePosition();
    }
};
