const std = @import("std");
const raylib = @import("raylib.zig");
const Tilemap = @import("Tilemap.zig");
const Tileset = @import("Tileset.zig");
const Actor = @import("Actor.zig");
const Level = @This();

const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

arena: ArenaAllocator,
tilemap: Tilemap,
character: *Actor,
enemies: ArrayList(*Actor),

pub fn init(level_png_path: []const u8, sprite_sheet_path: []const u8, character: *Actor, arena: *ArenaAllocator) !Level {
    const tileset = try Tileset.initFromSpriteSheet(sprite_sheet_path, arena);
    return Level{
        .tilemap = try Tilemap.initFromPngFile(level_png_path, tileset, arena),
        .enemies = ArrayList(*Actor).init(arena.allocator()),
        .character = character,
        .arena = arena.*,
    };
}

pub fn deinit(self: *Level) void {
    self.arena.deinit();
}

pub fn draw(self: Level) !void {
    try self.tilemap.draw();
    try self.drawActors();
}

fn drawActors(self: Level) !void {
    for (self.enemies.items) |actor| {
        self.drawActor(actor);
    }
    self.drawActor(self.character);
}

fn drawActor(self: Level, actor: *Actor) void {
    const level_x: c_int = @intFromFloat(self.tilemap.position.x);
    const level_y: c_int = @intFromFloat(self.tilemap.position.y);
    const x: c_int = level_x + actor.cell.x * Tilemap.tile_size;
    const y: c_int = level_y + actor.cell.y * Tilemap.tile_size;
    raylib.DrawTexture(actor.texture, x, y, raylib.WHITE);
}
