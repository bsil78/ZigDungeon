const std = @import("std");
const raylib = @import("raylib.zig");
const Tilemap = @import("Tilemap.zig");
const Tileset = @import("Tileset.zig");
const Actor = @import("Actor.zig");
const Inputs = @import("Inputs.zig");
const Vector = @import("Vector.zig");
const Observer = @import("Observer.zig");
const Callback = @import("Callback.zig");
const ActorAction = @import("ActorAction.zig");
const Globals = @import("Globals.zig");
const Vector2 = Vector.Vector2;
const Level = @This();

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const LevelError = error{ UnreachableTile, NonExistingActor };

pub const ActorType = enum { Character, Enemy };

allocator: Allocator,
tilemap: Tilemap,
actors: ArrayList(*Actor),

pub const ActorContext = struct {
    level: *Level,
    actor: *Actor,
};

pub fn init(level_png_path: []const u8, sprite_sheet_path: []const u8, allocator: Allocator) !Level {
    const tileset = try Tileset.initFromSpriteSheet(sprite_sheet_path, allocator);
    return Level{
        .tilemap = try Tilemap.initFromPngFile(level_png_path, tileset, allocator),
        .actors = ArrayList(*Actor).init(allocator),
        .allocator = allocator,
    };
}

pub fn deinit() !void {}

pub fn draw(self: *Level) !void {
    try self.tilemap.draw();
    try self.drawActors();
    try self.drawActionsPreview();
}

pub fn addActor(self: *Level, actor: *Actor) !void {
    try self.actors.append(actor);

    const context = ActorContext{ .level = self, .actor = actor };
    const callback = try Callback.init(self.allocator, ActorContext, onActorDied, context);
    try actor.event_emitter.subscribe(Actor.ActorEvents.Died, callback);
}

pub fn removeActor(self: *Level, actor: *Actor) !void {
    for (self.actors.items, 0..) |item, i| {
        if (actor == item) {
            _ = self.actors.swapRemove(i);
            break;
        }
    }
}

fn drawActors(self: *Level) !void {
    for (self.actors.items) |actor| {
        self.drawActor(actor);
    }
}

fn drawActor(self: *Level, actor: *Actor) void {
    const level_x: c_int = @intFromFloat(self.tilemap.position.x);
    const level_y: c_int = @intFromFloat(self.tilemap.position.y);
    const x: c_int = level_x + actor.cell.x * Tilemap.tile_size;
    const y: c_int = level_y + actor.cell.y * Tilemap.tile_size;
    raylib.DrawTexture(actor.texture, x, y, raylib.WHITE);
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

fn onActorDied(context: *ActorContext) !void {
    std.debug.print("Actor of type {s} died\n", .{@tagName(context.actor.actor_type)});
    try context.level.removeActor(context.actor);
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

        const rdm_id = Globals.random.int(usize) % cells.items.len;

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

fn drawActionsPreview(self: *Level) !void {
    for (self.actors.items) |actor| {
        if (actor.next_action) |action| {
            if (action.preview) |preview| {
                preview.draw(self);
            }
        }
    }
}
