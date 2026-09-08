// Datastructures library - collection of optimized data structures for ECS and game engines
// 
// Includes:
//   - SparseDenseSet: Generic sparse-dense set for cache-friendly component storage

// #region Namespace imports
const sparse_dense_set = @import("sparse_dense_set.zig");
// #endregion

// #region Concrete imports
pub const SparseDenseSet = sparse_dense_set.SparseDenseSet;
pub const SparseDenseSetType = sparse_dense_set.SparseDenseSetType;
// #endregion
