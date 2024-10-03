const std = @import("std");
const time = std.time;
const Allocator = std.mem.Allocator;
const globals = @This();

pub var random: std.Random = undefined;

pub fn init() !void {
    try initRandom();
}

fn initRandom() !void {
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    globals.random = prng.random();
}
