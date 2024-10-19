const std = @import("std");
const engine = @import("../engine/engine.zig");
const raylib = engine.raylib;
const Level = @import("Level.zig");
const ActorAction = @import("ActorAction.zig");
const ActionPreview = @import("ActionPreview.zig");
const CellTransform = @import("CellTransform.zig");
const traits = engine.traits;
const Actor = @This();

const Color = @import("../engine/color/Color.zig");
const Tilemap = engine.tiles.Tilemap;
const events = engine.events;
const Allocator = std.mem.Allocator;
const Vector2 = engine.maths.Vector.Vector2;
const EventEmitter = engine.events.EventEmitter;
const Sprite = engine.sprites.Sprite;
const Transform = engine.maths.Transform;

pub const ActorEvents = enum {
    Died,
};

pub const ActorType = enum {
    Character,
    Enemy,
};

allocator: Allocator = undefined,
event_emitter: EventEmitter(ActorEvents) = undefined,
sprite: *Sprite = undefined,
level: ?*Level = undefined,
next_action: ?*ActorAction = null,
actor_type: ActorType,
cell_transform: CellTransform,
hp: u16 = 1,
force: u16 = 1,

pub fn init(allocator: Allocator, texture_path: []const u8, cell: Vector2(i16), actor_type: ActorType, level: ?*Level) !*Actor {
    const parent_trans: ?*Transform = if (level) |lvl| &lvl.tilemap.transform else null;
    const ptr = try allocator.create(Actor);

    ptr.* = Actor{
        .actor_type = actor_type,
        .level = level,
        .cell_transform = CellTransform.init(cell, parent_trans),
        .event_emitter = try EventEmitter(ActorEvents).init(allocator),
        .allocator = allocator,
        .sprite = try Sprite.init(allocator, texture_path, &ptr.*.cell_transform.transform, 1, Color.white),
    };

    return ptr;
}

pub fn deinit(self: *Actor) !void {
    try self.sprite.deinit();
    self.allocator.destroy(self);
}

pub fn move(self: *Actor, dest_cell: Vector2(i16)) void {
    std.debug.print("Actor moved at cell x: {d} y: {d}\n", .{ dest_cell.x, dest_cell.y });
    self.cell_transform.move(dest_cell);
}

pub fn attack(self: *Actor, target: *Actor) !void {
    try target.damage(self.force);
}

pub fn damage(self: *Actor, amount: u16) !void {
    self.hp -= amount;

    if (self.hp == 0) {
        try self.die();
    }
}

fn die(self: *Actor) !void {
    try self.event_emitter.emit(ActorEvents.Died);
}
