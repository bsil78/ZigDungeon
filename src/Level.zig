const std = @import("std");
const raylib = @import("raylib.zig");
const Tilemap = @import("Tilemap.zig");
const Callback = @import("Callback.zig");
const Tileset = @import("Tileset.zig");
const Actor = @import("Actor.zig");
const Inputs = @import("Inputs.zig");
const Vector = @import("Vector.zig");
const Vector2 = Vector.Vector2;
const Level = @This();

const ArenaAllocator = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;

const LevelError = error{UnreachableTile};

pub const ActorType = enum { Character, Enemy };

arena: ArenaAllocator,
tilemap: Tilemap,
characters: ArrayList(*Actor),
enemies: ArrayList(*Actor),

pub fn init(level_png_path: []const u8, sprite_sheet_path: []const u8, arena: *ArenaAllocator) !Level {
    const tileset = try Tileset.initFromSpriteSheet(sprite_sheet_path, arena);
    return Level{
        .tilemap = try Tilemap.initFromPngFile(level_png_path, tileset, arena),
        .enemies = ArrayList(*Actor).init(arena.allocator()),
        .characters = ArrayList(*Actor).init(arena.allocator()),
        .arena = arena.*,
    };
}

pub fn deinit(self: *Level) void {
    self.arena.deinit();
}

pub fn draw(self: *Level) !void {
    try self.tilemap.draw();
    try self.drawActors();
}

pub fn addActor(self: *Level, actor_type: ActorType, actor: *Actor) !void {
    const array = switch (actor_type) {
        ActorType.Character => &self.characters,
        ActorType.Enemy => &self.enemies,
    };

    try array.append(actor);

    const context = .{ .self = self, .actor_type = actor_type, .actor = actor };
    const callback = Callback.init(@TypeOf(context), onActorDied, context);
    try actor.event_emitter.subscribe(Actor.ActorEvents.Died, callback);
}

pub fn removeActor(self: *Level, actor_type: ActorType, actor: *Actor) !void {
    var actor_array = switch (actor_type) {
        ActorType.Character => self.characters,
        ActorType.Enemy => self.enemies,
    };

    for (actor_array.items, 0..) |item, i| {
        if (actor == item) {
            try actor_array.orderedRemove(i);
            break;
        }
    }
}

fn getActorsArrays(self: Level) [2]ArrayList(*Actor) {
    return [2]ArrayList(*Actor){ self.characters, self.enemies };
}

fn drawActors(self: *Level) !void {
    for (self.getActorsArrays()) |actor_array| {
        for (actor_array.items) |actor| {
            self.drawActor(actor);
        }
    }
}

fn drawActor(self: *Level, actor: *Actor) void {
    const level_x: c_int = @intFromFloat(self.tilemap.position.x);
    const level_y: c_int = @intFromFloat(self.tilemap.position.y);
    const x: c_int = level_x + actor.cell.x * Tilemap.tile_size;
    const y: c_int = level_y + actor.cell.y * Tilemap.tile_size;
    raylib.DrawTexture(actor.texture, x, y, raylib.WHITE);
}

pub fn input(self: Level, inputs: Inputs) !void {
    if (!inputs.hasAction()) {
        return;
    }

    for (self.characters.items) |character| {
        const dir: Vector2(f32) = inputs.getDirection();
        const dest_cell = character.cell.add(dir.intFromFloat(i16));

        if (try self.tilemap.isCellWalkable(dest_cell) and try self.isCellFree(dest_cell)) {
            character.move(dest_cell);
        } else {
            return LevelError.UnreachableTile;
        }
    }
}

fn isCellFree(self: Level, cell: Vector2(i16)) Tilemap.TilemapError!bool {
    if (self.tilemap.tileExist(cell)) {
        return Tilemap.TilemapError.OutOfBound;
    }

    for (self.getActorsArrays()) |actor_array| {
        for (actor_array.items) |actor| {
            if (cell.equal(actor.cell)) {
                return false;
            }
        }
    }

    return true;
}

fn onActorDied(context: struct { self: *Level, actor_type: ActorType, actor: *Actor }) void {
    context.self.removeActor(context.actor_type, context.actor);
    std.debug.print("Actor died", .{});
}
