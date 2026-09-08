// #region Namespace imports
const std = @import("std");
const geometry = @import("production_geometry");
// #endregion

const Vector2 = geometry.vectors.Vector2;
const Rect = geometry.shapes.Rect;
const Transform = geometry.Transform;

test "vector arithmetic preserves component-wise laws" {
    const first = Vector2(i32).init(6, -2);
    const second = Vector2(i32).init(-4, 5);

    try std.testing.expectEqual(Vector2(i32).init(2, 3), first.add(second));
    try std.testing.expectEqual(Vector2(i32).init(10, -7), first.minus(second));
    try std.testing.expectEqual(Vector2(i32).init(-24, -10), first.times(second));
    const first_float = Vector2(f32).init(6.0, -2.0);
    try std.testing.expectEqual(Vector2(f32).init(-1.0, 1.0), first_float.divide(Vector2(f32).init(-6.0, -2.0)));
}

test "vector products follow their geometric definitions" {
    const x_axis = Vector2(f32).Right();
    const y_axis = Vector2(f32).Down();

    try std.testing.expectEqual(@as(f32, 0.0), x_axis.dot(&y_axis));
    try std.testing.expectEqual(@as(f32, 1.0), x_axis.cross(&y_axis));
    try std.testing.expectApproxEqAbs(std.math.pi / 2.0, x_axis.angleTo(&y_axis), 0.0001);
}

test "vector normalization and direction have unit length" {
    const source = Vector2(f32).init(3.0, 4.0);
    const normalized = source.normalized();
    const direction = Vector2(f32).Zero().directionTo(&source);

    try std.testing.expectApproxEqAbs(1.0, normalized.lenght(), 0.0001);
    try std.testing.expectApproxEqAbs(1.0, direction.lenght(), 0.0001);
    try std.testing.expectApproxEqAbs(0.6, normalized.x, 0.0001);
    try std.testing.expectApproxEqAbs(0.8, normalized.y, 0.0001);
}

test "rectangles center and expose position and size" {
    const child = Rect(f32).init(0.0, 0.0, 20.0, 10.0);
    const container = Rect(f32).init(10.0, 20.0, 100.0, 80.0);
    const centered = child.centerRect(container);

    try std.testing.expectEqual(Rect(f32).init(50.0, 55.0, 20.0, 10.0), centered);
    try std.testing.expectEqual(Vector2(f32).init(50.0, 55.0), centered.getRectPosition());
    try std.testing.expectEqual(Vector2(f32).init(20.0, 10.0), centered.getRectSize());
    try std.testing.expectEqual(Rect(f32).init(50.0, 55.0, 20.0, -10.0), centered.flipRectY());
}

test "transform composition combines translation, scale, and rotation" {
    const outer = Transform{
        .position = Vector2(f32).init(10.0, 20.0),
        .scale = Vector2(f32).init(2.0, 3.0),
        .rotation = 0.25,
    };
    const inner = Transform{
        .position = Vector2(f32).init(-4.0, 5.0),
        .scale = Vector2(f32).init(4.0, 5.0),
        .rotation = 0.5,
    };
    const composed = outer.xform(&inner);

    try std.testing.expectEqual(Vector2(f32).init(6.0, 25.0), composed.position);
    try std.testing.expectEqual(Vector2(f32).init(8.0, 15.0), composed.scale);
    try std.testing.expectApproxEqAbs(0.75, composed.rotation, 0.0001);
}