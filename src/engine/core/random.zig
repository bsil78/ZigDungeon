// #region Namespace imports
const std = @import("std");
// #endregion

pub const Mode = enum {
    live,
    fixed,
    record,
    replay,
};

pub const Config = struct {
    mode: Mode = .live,
    seed: u64 = 0,
    fixed_values: []const u64 = &.{},
};

pub const GameRandom = struct {
    allocator: std.mem.Allocator,
    mode: Mode,
    prng: std.Random.DefaultPrng,
    values: std.ArrayList(u64),
    source_values: []const u64,
    cursor: usize = 0,

    pub fn init(allocator: std.mem.Allocator, config: Config) !GameRandom {
        return .{
            .allocator = allocator,
            .mode = config.mode,
            .prng = std.Random.DefaultPrng.init(config.seed),
            .values = try std.ArrayList(u64).initCapacity(allocator, 64),
            .source_values = config.fixed_values,
        };
    }

    pub fn deinit(self: *GameRandom) void {
        self.values.deinit(self.allocator);
    }

    pub fn nextU64(self: *GameRandom) !u64 {
        const value = switch (self.mode) {
            .live => self.prng.random().int(u64),
            .fixed, .replay => try self.nextSourceValue(),
            .record => self.prng.random().int(u64),
        };

        if (self.mode == .record) try self.values.append(self.allocator, value);
        return value;
    }

    pub fn index(self: *GameRandom, length: usize) !usize {
        if (length == 0) return error.EmptyRange;
        return @intCast(try self.nextU64() % @as(u64, @intCast(length)));
    }

    pub fn recorded(self: *const GameRandom) []const u64 {
        return self.values.items;
    }

    fn nextSourceValue(self: *GameRandom) !u64 {
        if (self.cursor >= self.source_values.len) return error.RandomSequenceExhausted;

        const value = self.source_values[self.cursor];
        self.cursor += 1;
        return value;
    }
};