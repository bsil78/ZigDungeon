// #region Namespace imports
const std = @import("std");
const random = @import("engine/core/random.zig");
const color = @import("libs/gfx/color.zig");
const geometry = @import("libs/maths/geometry.zig");
const sparse_set = @import("libs/datastructs/sparse_dense_set.zig");
// #endregion

comptime {
    _ = random;
    _ = color;
    _ = geometry;
    _ = sparse_set;
}
