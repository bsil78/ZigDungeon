const std = @import("std");
const raylib = @import("../core/raylib.zig").raylib;

/// Create a Vector2 as follows: Vector2{x: T, y: T}
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

        pub fn equal(self: *const Vector2(T), to: *const Vector2(T)) bool {
            return self.x == to.x and self.y == to.y;
        }

        pub fn minus(self: *const Vector2(T), to: anytype) Vector2(T) {
            return switch (@typeInfo(@TypeOf(to))) {
                .@"struct", .pointer => Vector2(T).init(self.x - to.x, self.y - to.y),
                .int, .float, .comptime_int, .comptime_float => Vector2(T).init(self.x - to, self.y - to),
                else => unreachable,
            };
        }

        pub fn add(self: *const Vector2(T), to: anytype) Vector2(T) {
            return switch (@typeInfo(@TypeOf(to))) {
                .@"struct", .pointer => Vector2(T).init(self.x + to.x, self.y + to.y),
                .int, .float, .comptime_int, .comptime_float => Vector2(T).init(self.x + to, self.y + to),
                else => unreachable,
            };
        }

        pub fn times(self: *const Vector2(T), by: anytype) Vector2(T) {
            return switch (@typeInfo(@TypeOf(by))) {
                .@"struct", .pointer => Vector2(T).init(self.x * by.x, self.y * by.y),
                .int, .float, .comptime_int, .comptime_float => Vector2(T).init(self.x * by, self.y * by),
                else => unreachable,
            };
        }

        pub fn divide(self: *const Vector2(T), with: anytype) Vector2(T) {
            return switch (@typeInfo(@TypeOf(with))) {
                .@"struct", .pointer => Vector2(T).init(self.x / with.x, self.y / with.y),
                .int, .float, .comptime_int, .comptime_float => Vector2(T).init(self.x / with, self.y / with),
                else => unreachable,
            };
        }

        pub fn as(self: *const Vector2(T), TargetType: type) Vector2(TargetType) {
            return Vector2(TargetType).init(@as(TargetType, self.x), @as(TargetType, self.y));
        }

        pub fn toFloatV(self: *const Vector2(T), K: type) Vector2(K) {
            return switch (@typeInfo(T)) {
                .float, .comptime_float => self.as(f32),
                .int, .comptime_int => self.floatFromInt(K),
                else => unreachable,
            };
        }

        pub fn floatFromInt(self: *const Vector2(T), destType: type) Vector2(destType) {
            return Vector2(destType).init(
                @floatFromInt(self.x),
                @floatFromInt(self.y),
            );
        }

        pub fn intFromFloat(self: *const Vector2(T), destType: type) Vector2(destType) {
            return Vector2(destType).init(
                @intFromFloat(self.x),
                @intFromFloat(self.y),
            );
        }

        pub fn lenght(self: *const Vector2(T)) f32 {
            const v = self.toFloatV(f32);
            return @sqrt((v.x * v.x) + (v.y * v.y));
        }

        pub fn normalized(self: *const Vector2(T)) Vector2(f32) {
            const v = self.toFloatV(f32);
            const len = v.lenght();
            return Vector2(f32).init(v.x / len, v.y / len);
        }

        pub fn directionTo(self: *const Vector2(T), to: *const Vector2(T)) Vector2(f32) {
            return to.minus(self).normalized();
        }

        pub fn toRaylib(self: *const Vector2(T)) raylib.Vector2 {
            const v = self.toFloatV(f32);
            return raylib.Vector2{ .x = v.x, .y = v.y };
        }

        pub fn cross(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            return self.x * to.x - self.y * to.y;
        }

        pub fn dot(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            return self.x * to.x + self.y * to.y;
        }

        pub fn angle(self: *const Vector2(T)) f32 {
            return std.math.atan2(self.y, self.x);
        }

        pub fn angleTo(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            return std.math.atan2(self.cross(to), self.cross(to));
        }

        pub fn nearestCardinalDirection(self: *const Vector2(T)) Vector2(T) {
            var smallest_angle: f32 = std.math.floatMax(T);
            var nearest_dir = Vector2(T).Zero();

            for (CardinalDirections(T)) |dir| {
                const dir_angle = @abs(self.angleTo(&dir));
                if (dir_angle < smallest_angle) {
                    smallest_angle = dir_angle;
                    nearest_dir = dir;
                }
            }

            return nearest_dir;
        }
    };
}

pub fn CardinalDirections(T: type) [4]Vector2(T) {
    return [4]Vector2(T){
        Vector2(T).Right(),
        Vector2(T).Down(),
        Vector2(T).Left(),
        Vector2(T).Up(),
    };
}
