const std = @import("std");

const maths = @import("../libs/maths/maths.zig");
const Color = @import("../libs/gfx/gfx.zig").Color;

pub const core = @import("core/core.zig");
pub const sprites = @import("sprites/sprites.zig");
pub const tiles = @import("tiles/tiles.zig");
pub const utils = @import("utils/utils.zig");

var program_start_timestamp: u64 = 0;
var last_timestamp: u64 = 0;
var current_timestamp: u64 = 0;

pub var random: std.Random = undefined;
pub var process_time: f32 = 0.0;
pub var delta: f32 = 0.0;
pub var engine_allocator: std.mem.Allocator = undefined;
pub var frames_counter: u32 = 0;

var _prng: std.Random.DefaultPrng = undefined;
var _timer : core.GameTimer = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    _timer = core.GameTimer.start();
    program_start_timestamp = _timer.lap();
    current_timestamp = program_start_timestamp;
    last_timestamp = program_start_timestamp;

    engine_allocator = allocator;

    try core.renderer.init(engine_allocator);

    const seed = current_timestamp;
    _prng = std.Random.DefaultPrng.init(seed);
    random = _prng.random();
}

pub fn deinit() void {
    core.renderer.deinit();
}

pub fn mainLoop() !void {
    last_timestamp = current_timestamp;
    current_timestamp = _timer.lap();
    process_time = @as(f32, @floatFromInt(current_timestamp)) / 1000.0;
    delta = process_time;

    frames_counter += 1;
}

pub fn render() !void {
    try core.renderer.render();
}

pub fn process() !void {
    last_timestamp = current_timestamp;
    current_timestamp = std.time.milliTimestamp();
}

pub fn gameStartMs() i64 {
    return std.time.milliTimestamp() - program_start_timestamp;
}
