const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Vector = @import("Vector.zig");
const Vector2 = Vector.Vector2;
const Actor = @This();

cell: Vector2(i16),
texture: raylib.struct_Texture = undefined,

pub fn init(texture_path: []const u8, cell: Vector2(i16)) Actor {
    var actor = Actor{ .cell = cell };
    actor.texture = raylib.LoadTexture(texture_path.ptr);

    return actor;
}

pub fn move(self: *Actor, dest_cell: Vector2(i16)) void {
    self.cell = dest_cell;
}
