const std = @import("std");
const Allocator = std.mem.Allocator;
const raylib = @import("raylib.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Vector = @import("Vector.zig");
const Vector2 = Vector.Vector2;
const Observer = @import("Observer.zig");
const Actor = @This();

pub const ActorEvents = enum {
    Died,
};

event_emitter: Observer.EventEmitter(ActorEvents) = undefined,
texture: raylib.struct_Texture = undefined,
cell: Vector2(i16),
hp: u16 = 1,
force: u16 = 1,

pub fn init(texture_path: []const u8, cell: Vector2(i16), allocator: Allocator) !Actor {
    var actor = Actor{ .cell = cell };
    actor.texture = raylib.LoadTexture(texture_path.ptr);
    actor.event_emitter = try Observer.EventEmitter(ActorEvents).init(allocator);

    return actor;
}

pub fn move(self: *Actor, dest_cell: Vector2(i16)) void {
    self.cell = dest_cell;
}

pub fn attack(self: *Actor, target: *Actor) void {
    target.damage(self.force);
}

pub fn damage(self: *Actor, amount: u16) void {
    self.hp -= amount;

    if (self.hp == 0) {
        self.die();
    }
}

fn die(self: *Actor) void {
    self.event_emitter.emit(ActorEvents.Died);
}
