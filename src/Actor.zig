const std = @import("std");
const engine = @import("engine/engine.zig");
const raylib = engine.raylib;
const Level = @import("Level.zig");
const ActorAction = @import("ActorAction.zig");
const ActionPreview = @import("ActionPreview.zig");
const Actor = @This();

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

pub const ActionType = enum {
    Move,
    Attack,
};

event_emitter: EventEmitter(ActorEvents) = undefined,
sprite: Sprite = undefined,
next_action: ?ActorAction = null,
actor_type: ActorType,
cell: Vector2(i16),
hp: u16 = 1,
force: u16 = 1,

pub fn init(texture_path: []const u8, cell: Vector2(i16), actor_type: ActorType, allocator: Allocator) !Actor {
    var actor = Actor{ .cell = cell, .actor_type = actor_type };
    actor.sprite = Sprite.init(texture_path);
    actor.event_emitter = try EventEmitter(ActorEvents).init(allocator);

    return actor;
}

pub fn move(self: *Actor, dest_cell: Vector2(i16)) void {
    std.debug.print("Actor moved at cell x: {d} y: {d}\n", .{ dest_cell.x, dest_cell.y });
    self.cell = dest_cell;
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

pub fn planAction(self: *Actor, level: *Level, action_type: ActionType, cell: ?Vector2(i16)) void {
    self.next_action = ActorAction{
        .caster = self,
        .level = level,
        .action_type = action_type,
        .target_cell = cell,
    };

    self.next_action.?.preview = ActionPreview.init(cell.?, &self.next_action.?);
    std.debug.print("Actor planned to {s} at cell x: {d} y: {d}\n", .{ @tagName(action_type), cell.?.x, cell.?.y });
}

pub fn draw(self: *Actor, opt_transform: ?*const Transform) void {
    const actor_trans = Transform{
        .position = self.cell.times(Tilemap.tile_size).floatFromInt(f32),
        .rotation = 0.0,
        .scale = Vector2(f32).One(),
    };

    const result_trans = if (opt_transform) |trans| actor_trans.xform(trans) else actor_trans;

    self.sprite.draw(&result_trans);
}
