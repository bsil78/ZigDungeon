// #region Namespace imports
const std = @import("std");
const color = @import("production_color");
// #endregion

test "initHex" {
    try std.testing.expectEqual(try color.initHex("#FFFFFF"), color.init(255, 255, 255, 255));
    try std.testing.expectEqual(try color.initHex("#FF0000"), color.init(255, 0, 0, 255));
    try std.testing.expectEqual(try color.initHex("#00FF00"), color.init(0, 255, 0, 255));
    try std.testing.expectEqual(try color.initHex("0000FF"), color.init(0, 0, 255, 255));
    try std.testing.expectEqual(try color.initHex("#FFFFFF00"), color.init(255, 255, 255, 0));
}