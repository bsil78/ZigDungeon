const std = @import("std");
const time = std.time;
const Allocator = std.mem.Allocator;
const Globals = @This();

const program_start_timestamp = std.time.milliTimestamp();
var last_timestamp = 0;
var current_timestamp = program_start_timestamp;

pub var random: std.Random = undefined;
pub var process_time: f32 = 0.0;
pub var delta: f32 = 0.0;

pub fn init() !void {
    try initRandom();
}

fn initRandom() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    Globals.random = prng.random();
}

pub fn process() !void {
    last_timestamp = current_timestamp;
    current_timestamp = std.time.milliTimestamp();
}

/// Returns the amount of ms the game has been running
pub fn gameStartMs() i64 {
    return std.time.milliTimestamp() - program_start_timestamp;
}
