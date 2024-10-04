const std = @import("std");
const engine = @import("engine/engine.zig");
const Actor = @import("Actor.zig");
const ActorAction = @import("ActorAction.zig");
const Level = @This();

const raylib = engine.raylib;
const globals = engine.core.globals;
const callbacks = engine.events.callbacks;
const EventEmitter = engine.EventEmitter;
const Vector = engine.maths.Vector;
const Vector2 = Vector.Vector2;
const Tilemap = engine.tiles.Tilemap;
const Tileset = engine.tiles.Tileset;
const Inputs = engine.core.inputs;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const LevelError = error{ UnreachableTile, NonExistingActor };

pub const ActorType = enum { Character, Enemy };

allocator: Allocator,
tilemap: *Tilemap,
actors: ArrayList(*Actor),

pub const ActorContext = struct {
    level: *Level,
    actor: *Actor,
};

pub fn init(allocator: Allocator, level_png_path: []const u8, sprite_sheet_path: []const u8) !Level {
    const tileset = try Tileset.initFromSpriteSheet(sprite_sheet_path, allocator);
    return Level{
        .tilemap = try Tilemap.initFromPngFile(allocator, level_png_path, tileset),
        .actors = ArrayList(*Actor).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit(self: *Level) !void {
    try self.tilemap.deinit();
}

pub fn addActor(self: *Level, actor: *Actor) !void {
    try self.actors.append(actor);

    const context = ActorContext{ .level = self, .actor = actor };
    const callback = try callbacks.CallbackSubscribeContext.init(self.allocator, ActorContext, onActorDied, context);
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

pub fn input(self: *Level, inputs: *const Inputs) !void {
    if (!inputs.hasAction()) {
        return;
    }

    for (self.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Enemy) {
            continue;
        }

        var dir: Vector2(f32) = inputs.getDirection();
        const dest_cell = actor.cell.add(&dir.intFromFloat(i16));

        if (self.getActorOnCell(dest_cell)) |target| {
            try actor.attack(target);
        } else if (try self.isCellWalkable(dest_cell)) {
            actor.move(dest_cell);
        } else {
            return LevelError.UnreachableTile;
        }
    }

    try self.enemiesResolveActions();
    try self.enemiesPlanActions();
}

fn isCellFree(self: *Level, cell: Vector2(i16)) Tilemap.TilemapError!bool {
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
        if (cell.equal(&actor.cell)) {
            return actor;
        }
    }

    return null;
}

fn actorGetAccessibleCells(self: *Level, allocator: Allocator, actor: *Actor) !ArrayList(Vector2(i16)) {
    var array = ArrayList(Vector2(i16)).init(allocator);

    for (Vector.CardinalDirections(i16)) |dir| {
        const dest_cell = actor.cell.add(&dir);
        if (try self.isCellWalkable(dest_cell)) {
            try array.append(dest_cell);
        }
    }

    return array;
}

fn enemiesPlanActions(self: *Level) !void {
    for (self.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Character) {
            continue;
        }

        var cells = try self.actorGetAccessibleCells(self.allocator, actor);
        defer cells.deinit();

        if (cells.items.len == 0) {
            actor.next_action = null;
            continue;
        }

        const rdm_id = globals.random.int(usize) % cells.items.len;

        const dest_cell = cells.items[rdm_id];
        actor.planAction(self, Actor.ActionType.Move, dest_cell);
    }
}

fn enemiesResolveActions(self: *Level) !void {
    for (self.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Character) {
            continue;
        }

        if (actor.next_action) |action| {
            try action.resolve();
        }
    }
}

// Event callbacks
fn onActorDied(context: *ActorContext) !void {
    std.debug.print("Actor of type {s} died\n", .{@tagName(context.actor.actor_type)});
    try context.level.removeActor(context.actor);
}
