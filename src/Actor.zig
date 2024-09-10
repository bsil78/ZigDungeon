const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Cell = @import("Cell.zig");
const Inputs = @import("Inputs.zig");
const Actor = @This();

cell: Cell,
texture: raylib.struct_Texture = undefined,

pub fn init(texture_path: []const u8, cell: Cell) Actor {
    var actor = Actor{ .cell = cell };
    actor.texture = raylib.LoadTexture(texture_path.ptr);

    return actor;
}

pub fn input(self: *Actor, inputs: Inputs) void {
    if (!inputs.hasAction()) {
        return;
    }

    const dir: Cell = Cell.fromVec(inputs.getDirection());
    std.debug.print("moved to dir x:{d} y:{d}\n", .{ dir.x, dir.y });
    self.move(Cell.add(self.cell, dir));
}

fn move(self: *Actor, dest_cell: Cell) void {
    self.cell = dest_cell;
    //std.debug.print("moved to x:{d} y:{d}\n", .{ dest_cell.x, dest_cell.y });
}
