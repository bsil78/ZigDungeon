const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Cell = @import("Cell.zig");
const Actor = @This();

cell: Cell,
texture: raylib.struct_Texture = undefined,

pub fn init(texture_path: []const u8, cell: Cell) Actor {
    var actor = Actor{ .cell = cell };
    actor.texture = raylib.LoadTexture(texture_path.ptr);

    return actor;
}

pub fn move(self: *Actor, dest_cell: Cell) void {
    self.cell = dest_cell;
}
