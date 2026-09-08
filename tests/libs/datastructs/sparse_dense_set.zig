// #region Namespace imports
const std = @import("std");
const data_structures = @import("production_sparse_dense_set");
// #endregion

const Storage = data_structures.SparseDenseSet(u32, u32);

test "set inserts, updates, and retrieves components" {
    var storage = try Storage.init(std.testing.allocator);
    defer storage.deinit();

    try storage.set(20, 200);
    try storage.set(10, 101);

    try std.testing.expectEqual(@as(usize, 2), storage.count());
    try std.testing.expectEqual(@as(u32, 101), storage.get(10).?.*);
    try std.testing.expectEqual(@as(u32, 200), storage.get(20).?.*);
    try std.testing.expect(storage.contains(10));
    try std.testing.expect(!storage.contains(99));
}

test "remove preserves the remaining entity and updates its index" {
    var storage = try Storage.init(std.testing.allocator);
    defer storage.deinit();

    try storage.set(1, 11);
    try storage.set(2, 22);
    try storage.set(3, 33);
    storage.remove(2);

    try std.testing.expectEqual(@as(usize, 2), storage.count());
    try std.testing.expect(!storage.contains(2));
    try std.testing.expectEqual(@as(u32, 11), storage.get(1).?.*);
    try std.testing.expectEqual(@as(u32, 33), storage.get(3).?.*);
}

test "clear resets membership and iteration" {
    var storage = try Storage.init(std.testing.allocator);
    defer storage.deinit();

    try storage.set(1, 11);
    try storage.set(2, 22);
    storage.clear();

    try std.testing.expect(storage.isEmpty());
    try std.testing.expectEqual(@as(usize, 0), storage.count());
    try std.testing.expect(storage.get(1) == null);
    var iterator = storage.iter();
    try std.testing.expect(iterator.next() == null);
}

test "iterator yields each entity with its matching component" {
    var storage = try Storage.init(std.testing.allocator);
    defer storage.deinit();

    try storage.set(7, 70);
    try storage.set(8, 80);

    var iterator = storage.iter();
    var seen: usize = 0;
    while (iterator.next()) |entry| {
        try std.testing.expectEqual(entry.id * 10, entry.data.*);
        seen += 1;
    }
    try std.testing.expectEqual(@as(usize, 2), seen);
}
