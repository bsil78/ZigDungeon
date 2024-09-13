const raylib = @import("raylib.zig");

pub fn Vector2(T: type) type {
    return struct {
        x: T,
        y: T,

        pub fn init(x: T, y: T) Vector2(T) {
            return .{
                .x = x,
                .y = y,
            };
        }

        pub fn initOneValue(val: T) Vector2(T) {
            return .{
                .x = val,
                .y = val,
            };
        }

        pub fn add(self: Vector2(T), to: Vector2(T)) Vector2(T) {
            return Vector2(T).init(self.x + to.x, self.y + to.y);
        }

        pub fn equal(self: Vector2(T), to: Vector2(T)) bool {
            return self.x == to.x and self.y == to.y;
        }

        pub fn times(self: Vector2(T), by: Vector2(T)) Vector2(T) {
            return Vector2(T).init(self.x * by.x, self.y * by.y);
        }

        pub fn CardinalDirections() [4]Vector2(T) {
            return [4]Vector2(T){
                Vector2(T).Right(),
                Vector2(T).Down(),
                Vector2(T).Left(),
                Vector2(T).Up(),
            };
        }

        pub fn Zero() Vector2(T) {
            return Vector2(T).initOneValue(0);
        }

        pub fn One() Vector2(T) {
            return Vector2(T).initOneValue(1);
        }

        pub fn Up() Vector2(T) {
            return Vector2(T).init(0, -1);
        }

        pub fn Down() Vector2(T) {
            return Vector2(T).init(0, 1);
        }

        pub fn Left() Vector2(T) {
            return Vector2(T).init(-1, 0);
        }

        pub fn Right() Vector2(T) {
            return Vector2(T).init(1, 0);
        }

        pub fn as(self: Vector2(T), TargetType: type) Vector2(TargetType) {
            return Vector2(TargetType).init(@as(TargetType, self.x), @as(TargetType, self.y));
        }

        pub fn floatFromInt(self: Vector2(T), destType: type) Vector2(destType) {
            return Vector2(destType).init(
                @floatFromInt(self.x),
                @floatFromInt(self.y),
            );
        }

        pub fn intFromFloat(self: Vector2(T), destType: type) Vector2(destType) {
            return Vector2(destType).init(
                @intFromFloat(self.x),
                @intFromFloat(self.y),
            );
        }

        pub fn toRaylib(self: Vector2(T)) raylib.Vector2 {
            return raylib.Vector2{
                .x = self.x,
                .y = self.y,
            };
        }
    };
}
