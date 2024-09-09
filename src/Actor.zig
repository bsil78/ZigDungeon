const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Actor = @This();

cell: Tilemap.Cell,
texture: raylib.struct_Texture = undefined,

pub fn init(texture_path: []const u8, cell: Tilemap.Cell) Actor {
    var actor = Actor{ .cell = cell };
    actor.texture = raylib.LoadTexture(texture_path.ptr);

    return actor;
}
