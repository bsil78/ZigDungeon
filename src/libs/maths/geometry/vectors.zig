// #region Namespace imports
const std = @import("std");
// #endregion

pub fn Vector2(T: type) type {
    return struct {
        pub const SCALAR = T;

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
                .@"struct", .pointer => Vector2(T).init(
                    self.x * castMultiplier(by.x),
                    self.y * castMultiplier(by.y),
                ),
                .int, .float, .comptime_int, .comptime_float => {
                    const scalar = castMultiplier(by);
                    return Vector2(T).init(self.x * scalar, self.y * scalar);
                },
                else => @compileError("Vector2.times expects a numeric scalar or vector operand"),
            };
        }

        fn castMultiplier(value: anytype) T {
            return switch (@typeInfo(@TypeOf(value))) {
                .int, .comptime_int => switch (@typeInfo(T)) {
                    .int => @intCast(value),
                    .float => @floatFromInt(value),
                    else => @compileError("Vector2 component type must be an integer or float"),
                },
                .float, .comptime_float => switch (@typeInfo(T)) {
                    .float => @floatCast(value),
                    .int => @compileError("Cannot multiply an integer vector by a floating-point operand"),
                    else => @compileError("Vector2 component type must be an integer or float"),
                },
                else => @compileError("Vector2.times expects numeric operand components"),
            };
        }

        pub fn divide(self: *const Vector2(T), with: anytype) Vector2(T) {
            return switch (@typeInfo(@TypeOf(with))) {
                .@"struct", .pointer => Vector2(T).init(self.x / with.x, self.y / with.y),
                .int, .float, .comptime_int, .comptime_float => Vector2(T).init(self.x / with, self.y / with),
                else => unreachable,
            };
        }

        pub fn as(self: *const Vector2(T), comptime TargetType: type) Vector2(TargetType) {
            switch (@typeInfo(TargetType)) {
                .float, .comptime_float => return self.toFloatV(TargetType),
                .int, .comptime_int => return self.toIntV(TargetType),
                else => std.debug.panic("Cannot convert {s} to {s}", .{ @typeName(T), @typeName(TargetType) }),
            }
        }

        fn toFloatV(self: *const Vector2(T), K: type) Vector2(K) {
            return switch (@typeInfo(T)) {
                .float, .comptime_float => Vector2(K).init(@floatCast(self.x), @floatCast(self.y)),
                .int, .comptime_int => Vector2(K).init( @floatFromInt(self.x), @floatFromInt(self.y), ),
                else => unreachable,
            };
        }

        fn toIntV(self: *const Vector2(T), K: type) Vector2(K) {
            return switch (@typeInfo(T)) {
                .int, .comptime_int => Vector2(K).init(@intCast(self.x), @intCast(self.y)),
                .float, .comptime_float => Vector2(K).init( @intFromFloat(self.x), @intFromFloat(self.y), ),
                else => unreachable,
            };
        }

        pub fn length(self: *const Vector2(T)) f32 {
            const v = self.toFloatV(f32);
            return @sqrt((v.x * v.x) + (v.y * v.y));
        }

        pub fn normalized(self: *const Vector2(T)) Vector2(f32) {
            const v = self.toFloatV(f32);
            const len = v.length();
            return Vector2(f32).init(v.x / len, v.y / len);
        }

        pub fn directionTo(self: *const Vector2(T), to: *const Vector2(T)) Vector2(f32) {
            return to.minus(self).normalized();
        }

        pub fn cross(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            const first = self.toFloatV(f32);
            const second = to.toFloatV(f32);
            return first.x * second.y - first.y * second.x;
        }

        pub fn dot(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            return self.x * to.x + self.y * to.y;
        }

        pub fn angle(self: *const Vector2(T)) f32 {
            return std.math.atan2(self.y, self.x);
        }

        pub fn angleTo(self: *const Vector2(T), to: *const Vector2(T)) f32 {
            return std.math.atan2(self.cross(to), self.dot(to));
        }

        pub fn nearestCardinalDirection(self: *const Vector2(T)) Vector2(T) {
            var smallest_angle: f32 = std.math.floatMax(T);
            var nearest_dir = Vector2(T).Zero();

            for (cardinalDirections(T)) |dir| {
                const dir_angle = @abs(self.angleTo(&dir));
                if (dir_angle < smallest_angle) {
                    smallest_angle = dir_angle;
                    nearest_dir = dir;
                }
            }

            return nearest_dir;
        }

        pub fn cardinalDirections() [4]Vector2(T) {
            return [4]Vector2(T){
                Vector2(T).Up(),
                Vector2(T).Right(),
                Vector2(T).Down(),
                Vector2(T).Left(),
            };
        }
    };
}
