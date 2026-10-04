// #region Namespace imports
const vectors = @import("../geometry/vectors.zig");
// #endregion

// #region Concrete imports
const Vector2 = vectors.Vector2;
// #endregion

pub fn Rect(comptime T: type) type {
    return struct {
        pub const SCALAR: type = T;

        x: T,
        y: T,
        w: T,
        h: T,

        pub fn init(x: T, y: T, w: T, h: T) Rect(T) {
            return .{ .x = x, .y = y, .w = w, .h = h };
        }

        pub fn initPV(pos: Vector2(T), size: Vector2(T)) Rect(T) {
            return .{ .x = pos.x, .y = pos.y, .w = size.x, .h = size.y };
        }

        pub fn initV(size: Vector2(T)) Rect(T) {
            return .{ .x = @as(T, 0), .y = @as(T, 0), .w = size.x, .h = size.y };
        }

        pub fn centerRect(self: Rect(T), container_rect: Rect(T)) Rect(T) {
            return Rect(T).init(
                container_rect.x + (container_rect.w / 2.0) - (self.w / 2.0),
                container_rect.y + (container_rect.h / 2.0) - (self.h / 2.0),
                self.w,
                self.h,
            );
        }

        pub fn flipRectY(self: Rect(T)) Rect(T) {
            return Rect(T).init(self.x, self.y, self.w, -self.h);
        }

        pub fn getRectPosition(self: Rect(T)) Vector2(T) {
            return Vector2(T).init(self.x, self.y);
        }

        pub fn getRectSize(self: Rect(T)) Vector2(T) {
            return Vector2(T).init(self.w, self.h);
        }

        pub fn contains(self: Rect(T), other: Rect(T)) bool {
            return self.x <= other.x and self.y <= other.y and self.x + self.w >= other.x + other.w and self.y + self.h >= other.y + other.h;
        }
    };
}
