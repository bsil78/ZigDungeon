// #region Namespace imports
const std = @import("std");
// #endregion

pub const LiveRandom = struct {
    seed: u64 = 0,
    values: [512]u64 = undefined,
    values_cursor: usize = 0,
    prng: std.Random.DefaultPrng,
    flush_values_fn: *const fn (*const [512]u64) GameRandom.Error!void,

    pub fn init(seed: u64, flush_values_fn: *const fn (*const [512]u64) GameRandom.Error!void) !LiveRandom {
        return .{ .seed = seed, .prng = std.Random.DefaultPrng.init(seed), .flush_values_fn = flush_values_fn };
    }

    pub fn nextU64(self: *LiveRandom) !u64 {
        const value = self.prng.random().int(u64);
        try self.saveValue(value);
        return value;
    }

    fn saveValue(self: *LiveRandom, value: u64) !void {
        self.values[self.values_cursor] = value;
        if (self.values_cursor == 511) {
            try self.flush_values_fn(&self.values);
            self.values_cursor = 0;
            return;
        }
        self.values_cursor = self.values_cursor + 1;
    }
};

pub const ReplayRandom = struct {
    source_values: [512]u64 = undefined,
    source_cursor: usize = 0,
    source_values_length: u8 = 0,
    source_values_read_next_chunk_fn: *const fn (*[512]u64) GameRandom.Error!u8,

    pub fn init(source_values_read_next_chunk_fn: *const fn (*[512]u64) GameRandom.Error!u8) !ReplayRandom {
        const replay = ReplayRandom{ .source_values_read_next_chunk_fn = source_values_read_next_chunk_fn };
        try replay.read_next_source_values();
        return replay;
    }

    pub fn nextU64(self: *ReplayRandom) !u64 {
        if (self.source_cursor >= self.source_values.len) {
            try self.read_next_source_values();
        }
        const value = self.source_values[self.source_cursor];
        self.source_cursor += 1;
        return value;
    }

    fn read_next_source_values(self: *ReplayRandom) !void {
        self.source_cursor = 0;
        self.source_values_length = try self.source_values_read_next_chunk_fn(&self.source_values);
        if (self.source_values_length == 0) return error.RandomSequenceExhausted;
    }
};

pub const RandomMode = union(enum) { live: LiveRandom, replay: ReplayRandom };

pub const GameRandom = struct {
    mode: RandomMode,

    pub const Error = error{ READ_ERROR, WRITE_ERROR };

    pub fn init(mode: RandomMode) !GameRandom {
        return GameRandom{
            .mode = mode,
        };
    }

    pub fn nextU64(self: *GameRandom) !u64 {
        return switch (self.mode) {
            .live => |*live| live.nextU64(),
            .replay => |*replay| replay.nextU64(),
        };
    }

    pub fn index(self: *GameRandom, length: usize) !usize {
        if (length == 0) return error.EmptyRange;
        const picked = try self.nextU64();
        //std.log.info("Random picked {d} for {d}", .{ picked, length });
        return @intCast(picked % @as(u64, @intCast(length)));
    }
};
