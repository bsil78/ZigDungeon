const std = @import("std");
const engine = @import("../engine/engine.zig");
const Actor = @import("Actor.zig");
const actions = @import("actions.zig");
const Level = @This();

const raylib = engine.raylib;
const callbacks = engine.events.callbacks;
const EventEmitter = engine.EventEmitter;
const Vector = engine.maths.Vector;
const Vector2 = Vector.Vector2;
const Tilemap = engine.tiles.Tilemap;
const Tileset = engine.tiles.Tileset;
const Inputs = engine.core.Inputs;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const ActionPreview = actions.ActionPreview;

const LevelError = error{ UnreachableTile, NonExistingActor };
pub const ActorType = enum { Character, Enemy };

allocator: Allocator,
tilemap: *Tilemap,
actors: ArrayList(*Actor),

pub fn init(allocator: Allocator, level_png_path: []const u8, sprite_sheet_path: []const u8) !*Level {
    const ptr = try allocator.create(Level);
    const tileset = try Tileset.initFromSpriteSheet(allocator, sprite_sheet_path);

    ptr.* = .{
        .tilemap = try Tilemap.initFromPngFile(allocator, level_png_path, tileset),
        .actors = try ArrayList(*Actor).initCapacity(allocator,16),
        .allocator = allocator,
    };

    return ptr;
}

pub fn deinit(self: *Level) !void {
    try self.tilemap.deinit();
}

pub fn addActor(self: *Level, actor: *Actor) !void {
    self.actors.appendAssumeCapacity(actor);

    const callback = try callbacks.CallbackSubscribeContext.init(Level, Actor, onActorDied, self, actor);
    const callback_type = callbacks.CallbackType{ .sub_context = callback };
    try actor.event_emitter.subscribe(Actor.ActorEvents.Died, callback_type);
}

pub fn removeActor(self: *Level, actor: *Actor) !void {
    for (self.actors.items, 0..) |item, i| {
        if (actor == item) {
            _ = self.actors.swapRemove(i);
            break;
        }
    }
}

pub fn isCellFree(self: *Level, cell: Vector2(i16)) Tilemap.TilemapError!bool {
    if (self.tilemap.tileExist(cell)) {
        return Tilemap.TilemapError.OutOfBound;
    }

    return (self.getActorOnCell(cell) == null);
}

pub fn isCellWalkable(self: *Level, cell: Vector2(i16)) Tilemap.TilemapError!bool {
    return try self.isCellFree(cell) and try self.tilemap.isCellWalkable(cell);
}

pub fn getActorOnCell(self: *Level, cell: Vector2(i16)) ?*Actor {
    for (self.actors.items) |actor| {
        if (cell.equal(&actor.cell_transform.cell)) {
            return actor;
        }
    }

    return null;
}

pub fn getActorsInArea(self: *Level, alloactor: Allocator, area: []Vector2(i16)) !ArrayList(*Actor) {
    var actors = try ArrayList(*Actor).initCapacity(alloactor,16);
    for (area) |cell| {
        if (self.getActorOnCell(cell)) |actor| {
            actors.appendAssumeCapacity(actor);
        }
    }
    return actors;
}

/// Get the accessible cells adjacents to the given cell
pub fn getAccessibleCells(self: *Level, allocator: Allocator, cell: Vector2(i16)) !ArrayList(Vector2(i16)) {
    var array = try ArrayList(Vector2(i16)).initCapacity(allocator,8);

    for (Vector.CardinalDirections(i16)) |dir| {
        const dest_cell = cell.add(&dir);
        if (try self.isCellWalkable(dest_cell)) {
            array.appendAssumeCapacity(dest_cell);
        }
    }

    return array;
}

// Event callbacks
fn onActorDied(self: *Level, actor: *Actor) !void {
    std.debug.print("Actor of type {s} died\n", .{@tagName(actor.actor_type)});
    try self.removeActor(actor);
}
