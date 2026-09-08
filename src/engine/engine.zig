// #region Namespace imports
const std = @import("std");
const maths = @import("../libs/maths/maths.zig");
pub const core = @import("core/core.zig");
pub const sprites = @import("sprites/sprites.zig");
pub const tiles = @import("tiles/tiles.zig");
pub const utils = @import("utils/utils.zig");
const project_settings = @import("../game/project_settings.zig");
// #endregion

// #region Concrete imports
const Color = @import("../libs/gfx/gfx.zig").Color;
// #endregion

var program_start_timestamp: u64 = 0;
var last_timestamp: u64 = 0;
var current_timestamp: u64 = 0;

pub var random: core.random.GameRandom = undefined;
pub var process_time: f32 = 0.0;
pub var delta: f32 = 0.0;
pub var engine_allocator: std.mem.Allocator = undefined;
pub var frames_counter: u32 = 0;

var _timer : core.GameTimer = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    _timer = core.GameTimer.start();
    program_start_timestamp = _timer.lap();
    current_timestamp = program_start_timestamp;
    last_timestamp = program_start_timestamp;

    engine_allocator = allocator;

    try core.renderer.init( engine_allocator, 
                            .{
                                .window_size = project_settings.window_size,
                                .window_rect = project_settings.window_rect,
                                .target_fps = project_settings.target_fps,
                            },
                            project_settings.game_name );

    var random_config = project_settings.random_config;
    if (random_config.seed == 0) random_config.seed = current_timestamp;
    random = try core.random.GameRandom.init(engine_allocator, random_config);
}

pub fn deinit() void {
    random.deinit();
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
