const builtin = @import("builtin");
const Vector2 = @import("../../../libs/libs.zig").maths.geometry.vectors.Vector2;

const raylib = @import("../vendors.zig").raylib;
const rlh = @import("../vendors.zig").raylib_helper;

pub const Windows = struct {
    pub const TYPES = struct {
        pub const WindowsPoint = extern struct {
            x: i32,
            y: i32,
        };
    };

    pub const API = struct {
        pub extern "user32" fn GetCursorPos(point: *TYPES.WindowsPoint) callconv(.winapi) i32;
        pub extern "user32" fn ScreenToClient(window: ?*anyopaque, point: *TYPES.WindowsPoint) callconv(.winapi) i32;
    };
};
