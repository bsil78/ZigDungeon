const std = @import("std");

pub fn random() !std.Random {
    var prng = std.Random.DefaultPrng.init(12345);
    return prng.random();
}
