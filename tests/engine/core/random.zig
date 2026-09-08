// #region Namespace imports
const std = @import("std");
const random_module = @import("production_random");
// #endregion

test "recorded random values can be replayed" {
    var recording = try random_module.GameRandom.init(std.testing.allocator, .{
        .mode = .record,
        .seed = 12345,
    });
    defer recording.deinit();

    _ = try recording.nextU64();
    _ = try recording.nextU64();

    var replay = try random_module.GameRandom.init(std.testing.allocator, .{
        .mode = .replay,
        .fixed_values = recording.recorded(),
    });
    defer replay.deinit();

    try std.testing.expectEqual(recording.recorded()[0], try replay.nextU64());
    try std.testing.expectEqual(recording.recorded()[1], try replay.nextU64());
    try std.testing.expectError(error.RandomSequenceExhausted, replay.nextU64());
}

test "fixed values drive bounded indexes" {
    const fixed_values = [_]u64{ 4, 7 };
    var random = try random_module.GameRandom.init(std.testing.allocator, .{
        .mode = .fixed,
        .fixed_values = &fixed_values,
    });
    defer random.deinit();

    try std.testing.expectEqual(@as(usize, 1), try random.index(3));
    try std.testing.expectEqual(@as(usize, 3), try random.index(4));
}