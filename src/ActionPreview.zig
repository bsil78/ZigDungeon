const ActorAction = @import("ActorAction.zig");
const Actor = @import("Actor.zig");
const raylib = @import("raylib.zig");
const Tilemap = @import("Tilemap.zig");
const Vector2 = @import("Vector.zig").Vector2;
const ActionPreview = @This();

const arrow_texture = raylib.LoadTexture("sprites/ui/EnemyActions");

cell : Vector2(i16),
action_type : Actor.ActionType,

pub fn draw(self: *ActionPreview, tilemap: *Tilemap) void {
    const cell = self.action.target_cell;
    const pos = cell.times(tilemap.grid_size.as(i16));
    raylib.DrawTexture(self.arrow_texture, pos.x, pos.y, raylib.WHITE);
}