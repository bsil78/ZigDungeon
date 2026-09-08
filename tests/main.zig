// #region Namespace imports
const std = @import("std");
const random_tests = @import("engine/core/random.zig");
const color_tests = @import("libs/gfx/color.zig");
const geometry_tests = @import("libs/maths/geometry.zig");
const sparse_dense_set_tests = @import("libs/datastructs/sparse_dense_set.zig");
// #endregion

comptime {
    _ = random_tests;
    _ = color_tests;
    _ = geometry_tests;
    _ = sparse_dense_set_tests;
}
