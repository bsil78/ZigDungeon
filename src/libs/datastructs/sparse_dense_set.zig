const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// Generic Sparse-Dense Component Storage
/// Optimized for cache-friendly iteration and O(1) operations
/// 
/// Type parameters:
///   - ComponentType: The data type stored in this set
///   - EntityIDType: The entity identifier type (e.g., u32, u64)
/// 
/// Usage example:
///   ```zig
///   const PositionStorage = SparseDenseSet(Position, EntityID);
///   var storage = try PositionStorage.init(allocator);
///   try storage.set(entity_id, position_data);
///   if (storage.get(entity_id)) |pos| { ... }
///   for (storage.entities()) |id| { ... }
///   ```
pub fn SparseDenseSet(ComponentType: type, EntityIDType: type) type {
    return struct {
        const Self = @This();
        const EntityID = EntityIDType;
        const Component = ComponentType;

        // Sparse index: EntityID → dense array index (O(1) lookup)
        sparse: std.AutoHashMap(EntityID, usize),

        // Dense storage: contiguous data for cache-friendly iteration
        dense_entities: ArrayList(EntityID),
        dense_data: ArrayList(Component),

        allocator: Allocator,

        /// Initialize a new empty sparse-dense set
        /// O(1) average case
        pub fn init(allocator: Allocator) !Self {
            return .{
                .sparse = std.AutoHashMap(EntityID, usize).init(allocator),
                .dense_entities = try ArrayList(EntityID).initCapacity(allocator, 32),
                .dense_data = try ArrayList(Component).initCapacity(allocator, 32),
                .allocator = allocator,
            };
        }

        /// Free all allocated resources
        pub fn deinit(self: *Self) void {
            self.sparse.deinit();
            self.dense_entities.deinit(self.allocator);
            self.dense_data.deinit(self.allocator);
        }

        /// Set or insert component data for entity
        /// If entity already has this component, updates it in-place
        /// O(1) average case
        pub fn set(self: *Self, entity_id: EntityID, component_data: Component) !void {
            if (self.sparse.get(entity_id)) |index| {
                // Entity exists, update in-place (no reallocation needed)
                self.dense_data.items[index] = component_data;
            } else {
                // New entity, append to dense arrays
                const new_index = self.dense_entities.items.len;
                try self.dense_entities.append(self.allocator, entity_id);
                try self.dense_data.append(self.allocator, component_data);
                try self.sparse.put(entity_id, new_index);
            }
        }

        /// Get immutable reference to component data
        /// Returns null if entity doesn't have this component
        /// O(1) average case via sparse lookup
        pub fn get(self: *const Self, entity_id: EntityID) ?*const Component {
            if (self.sparse.get(entity_id)) |index| {
                return &self.dense_data.items[index];
            }
            return null;
        }

        /// Get mutable reference to component data
        /// Returns null if entity doesn't have this component
        /// O(1) average case via sparse lookup
        pub fn getMut(self: *Self, entity_id: EntityID) ?*Component {
            if (self.sparse.get(entity_id)) |index| {
                return &self.dense_data.items[index];
            }
            return null;
        }

        /// Check if entity has this component
        /// O(1) average case
        pub fn contains(self: *const Self, entity_id: EntityID) bool {
            return self.sparse.contains(entity_id);
        }

        /// Remove component from entity using swap-remove for O(1) efficiency
        /// Swaps removed element with last element, avoiding gaps in dense array
        /// O(1) average case
        pub fn remove(self: *Self, entity_id: EntityID) void {
            if (self.sparse.get(entity_id)) |index| {
                // Swap with last element if not already last
                const last_index = self.dense_entities.items.len - 1;
                if (index != last_index) {
                    const last_entity_id = self.dense_entities.items[last_index];

                    // Move last element to removed position
                    self.dense_entities.items[index] = last_entity_id;
                    self.dense_data.items[index] = self.dense_data.items[last_index];

                    // Update sparse index for swapped element
                    self.sparse.put(last_entity_id, index) catch {};
                }

                // Remove last element
                _ = self.dense_entities.pop();
                _ = self.dense_data.pop();
            }
            _ = self.sparse.remove(entity_id);
        }

        /// Get slice of entity IDs (dense array for cache-friendly iteration)
        /// Use this for iterating over all entities with this component
        /// Cache-friendly: O(n) linear scan with excellent cache locality
        pub fn entities(self: *const Self) []const EntityID {
            return self.dense_entities.items;
        }

        /// Get mutable slice of component data
        pub fn data(self: *Self) []Component {
            return self.dense_data.items;
        }

        /// Get immutable slice of component data
        pub fn dataConst(self: *const Self) []const Component {
            return self.dense_data.items;
        }

        /// Count of entities with this component
        pub fn count(self: *const Self) usize {
            return self.dense_entities.items.len;
        }

        /// Check if set is empty
        pub fn isEmpty(self: *const Self) bool {
            return self.dense_entities.items.len == 0;
        }

        /// Clear all components without deallocating capacity
        /// Useful for resetting between frames or sim restarts
        pub fn clear(self: *Self) void {
            self.sparse.clearRetainingCapacity();
            self.dense_entities.clearRetainingCapacity();
            self.dense_data.clearRetainingCapacity();
        }

        /// Iterator for convenient for-each loops
        /// Example: for (storage.iter()) |entry| { ... }
        pub fn iter(self: *const Self) SetIterator {
            return SetIterator{
                .entities = self.dense_entities.items,
                .data = self.dense_data.items,
                .index = 0,
            };
        }

        /// Entry returned by iterator
        pub const IterEntry = struct {
            id: EntityID,
            data: *const Component,
        };

        /// Internal iterator structure
        pub const SetIterator = struct {
            entities: []const EntityID,
            data: []const Component,
            index: usize = 0,

            pub fn next(self: *SetIterator) ?IterEntry {
                if (self.index >= self.entities.len) return null;
                defer self.index += 1;
                return .{
                    .id = self.entities[self.index],
                    .data = &self.data[self.index],
                };
            }
        };

        /// Get statistics about memory usage
        pub fn stats(self: *const Self) Stats {
            return .{
                .count = self.dense_entities.items.len,
                .sparse_buckets = self.sparse.capacity(),
                .dense_capacity = self.dense_entities.capacity,
            };
        }

        /// Statistics structure
        pub const Stats = struct {
            count: usize,
            sparse_buckets: usize,
            dense_capacity: usize,
        };
    };
}

/// Convenience function to create a SparseDenseSet type
/// Usage: const Storage = SparseDenseSetType(Position, u32);
pub fn SparseDenseSetType(ComponentType: type, EntityIDType: type) type {
    return SparseDenseSet(ComponentType, EntityIDType);
}
