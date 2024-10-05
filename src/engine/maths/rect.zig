const raylib = @import("../core/raylib.zig");
const maths = @import("maths.zig");
const Vector = maths.Vector;
const Vector2 = maths.Vector.Vector2;

pub fn Rect(T: type) type {
    return struct {
        x: T,
        y: T,
        w: T,
        h: T,

        /// Create a rect
        pub fn init(x: T, y: T, w: T, h: T) Rect(T) {
            return .{ .x = x, .y = y, .w = w, .h = h };
        }

        /// Create a rect out of two vectors: position and size
        pub fn initV(pos: Vector2(T), size: Vector2(T)) Rect(T) {
            return .{ .x = pos.x, .y = pos.y, .w = size.x, .h = size.y };
        }

        /// Center the Rect in the given container Rect and return the result Rect
        pub fn centerRect(self: Rect(T), container_rect: Rect(T)) Rect(T) {
            return Rect(T).init(
                container_rect.x + (container_rect.w / 2.0) - (self.w / 2.0),
                container_rect.y + (container_rect.h / 2.0) - (self.h / 2.0),
                self.w,
                self.h,
            );
        }

        /// Flip the rect vertically
        pub fn flipRectY(self: Rect(T)) Rect(T) {
            return Rect(T).init(self.x, self.y, self.w, -self.h);
        }

        /// Returns the rect's position
        pub fn getRectPosition(self: Rect(T)) Vector2(T) {
            return Vector2(T).init(self.x, self.y);
        }

        /// Returns the rect's size
        pub fn getRectSize(self: Rect(T)) Vector2(T) {
            return Vector2(T).init(self.w, self.h);
        }

        /// Convert this rect to a raylib Rectangle struct
        pub fn toRaylib(self: Rect(T)) raylib.Rectangle {
            return raylib.Rectangle{
                .x = self.x,
                .y = self.y,
                .width = self.w,
                .height = self.h,
            };
        }
    };
}
