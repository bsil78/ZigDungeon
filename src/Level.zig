const Tilemap = @import("Tilemap.zig");
const Level = @This();

tilemap: Tilemap = Tilemap{},

pub fn draw(self: Level) void {
    self.tilemap.draw();
}
