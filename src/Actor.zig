const std = @import("std");
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Vector = @import("Vector.zig");
const Observer = @import("Observer.zig");
const ActorAction = @import("ActorAction.zig");
const ActionPreview = @import("ActionPreview.zig");
const Actor = @This();

const Allocator = std.mem.Allocator;
const Vector2 = Vector.Vector2;

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

event_emitter: Observer.EventEmitter(ActorEvents) = undefined,
texture: raylib.struct_Texture = undefined,
next_action: ?ActorAction = null,
actor_type: ActorType,
cell: Vector2(i16),
hp: u16 = 1,
force: u16 = 1,

pub fn init(texture_path: []const u8, cell: Vector2(i16), actor_type: ActorType, allocator: Allocator) !Actor {
    var actor = Actor{ .cell = cell, .actor_type = actor_type };
    actor.texture = raylib.LoadTexture(texture_path.ptr);
    actor.event_emitter = try Observer.EventEmitter(ActorEvents).init(allocator);

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
