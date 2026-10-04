// #region Namespace imports
const std = @import("std");
const libs = @import("../libs/libs.zig");
const maths = libs.maths;
pub const vendors = @import("vendors/vendors.zig");
pub const core = @import("core/core.zig");
const rendering = core.rendering;
pub const resources = @import("resources/resources.zig");
pub const utils = @import("utils/utils.zig");
// #endregion

// #region Concrete imports
const Color = libs.gfx.Color;
const UserSettings = core.UserSettings;
const Renderer = rendering.Renderer;
const Timer = libs.time.measurement.Timer;
const GameRandom = core.random.GameRandom;
// #endregion

pub var random: GameRandom = undefined;
pub var process_time: f32 = 0.0;
pub var delta: f32 = 0.0;
pub var frames_counter: u32 = 0;

var _renderer_queue_size: u16 = 0;
var _timer: Timer = undefined;
var _program_start_timestamp: u64 = 0;
var _last_timestamp: u64 = 0;
var _current_timestamp: u64 = 0;

pub fn init(settings: UserSettings, comptime MAX_RENDERABLES: u16, comptime MAX_CONTEXT_SIZE: usize) !Renderer(MAX_RENDERABLES, MAX_CONTEXT_SIZE) {
    _timer = Timer{};
    _program_start_timestamp = _timer.start();
    _current_timestamp = _program_start_timestamp;
    _last_timestamp = _program_start_timestamp;
    _renderer_queue_size = MAX_RENDERABLES;
    random = try GameRandom.init(settings.random_mode);

    return try Renderer(MAX_RENDERABLES, MAX_CONTEXT_SIZE).init(.{
        .window_size = settings.window_size,
        .window_rect = settings.window_rect,
        .target_fps = settings.target_fps,
    }, settings.game_name);
}

pub fn mainLoop() !void {
    _last_timestamp = _current_timestamp;
    _current_timestamp = _timer.lap();
    process_time = @as(f32, @floatFromInt(_current_timestamp)) / 1000.0;
    delta = process_time;
    frames_counter += 1;
}

pub fn process() !void {
    _last_timestamp = _current_timestamp;
    _current_timestamp = Timer.getNs();
}

pub fn gameRunningTime() i64 {
    return Timer.getNs() - _program_start_timestamp;
}
