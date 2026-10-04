// #region Namespace imports
const game = @import("game/game.zig");
// #endregion

// main function: entry point of the program
pub fn main() !void {
    try game.start();
}
