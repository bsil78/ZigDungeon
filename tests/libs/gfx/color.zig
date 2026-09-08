// #region Namespace imports
const std = @import("std");
const color_module = @import("production_color");
// #endregion

test "initHex" {
    try std.testing.expectEqual(try color_module.initHex("#FFFFFF"), color_module.init(255, 255, 255, 255));
    try std.testing.expectEqual(try color_module.initHex("#FF0000"), color_module.init(255, 0, 0, 255));
    try std.testing.expectEqual(try color_module.initHex("#00FF00"), color_module.init(0, 255, 0, 255));
    try std.testing.expectEqual(try color_module.initHex("0000FF"), color_module.init(0, 0, 255, 255));
    try std.testing.expectEqual(try color_module.initHex("#FFFFFF00"), color_module.init(255, 255, 255, 0));
}