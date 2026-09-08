// #region Namespace imports
const std = @import("std");
// #endregion

const SpriteAnimations = @This();

animations: std.AutoHashMap([]const u8, Animation),

const Animation = struct {
    start_frame: u16,
    end_frame: u16,
    fps: u8,
    loop: bool,
};
