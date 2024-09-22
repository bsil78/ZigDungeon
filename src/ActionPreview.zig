const ActorAction = @import("ActorAction.zig");
const std = @import("std");
const raylib = @import("raylib.zig");
const trigo = @import("trigo.zig");
const Level = @import("Level.zig");
const Tilemap = @import("Tilemap.zig");
const Rect = @import("Rect.zig").Rect;
const Vector2 = @import("Vector.zig").Vector2;
const ActionPreview = @This();

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

cell: Vector2(i16),
action: *ActorAction,
arrow_texture: raylib.Texture2D = undefined,

pub fn init(cell: Vector2(i16), action: *ActorAction) ActionPreview {
    return ActionPreview{
        .cell = cell,
        .action = action,
        .arrow_texture = raylib.LoadTexture(arrow_texture_path),
    };
}

pub fn draw(self: *const ActionPreview, level: *Level) void {
    const cell = self.action.target_cell.?;
    const f_tile_size: f32 = @floatFromInt(Tilemap.tile_size);
    const tile_size = Vector2(f32).One().times(f_tile_size);
    const dir = self.action.caster.cell.directionTo(&cell);
    const rot = trigo.radToDeg(f32, dir.angle());
    const pivot = tile_size.divide(2.0);
    const pos = cell.toFloatV(f32).times(&tile_size).add(&level.tilemap.position).add(&pivot);

    raylib.DrawTexturePro(
        self.arrow_texture,
        Rect(f32).initV(Vector2(f32).Zero(), tile_size).toRaylib(),
        Rect(f32).initV(pos, tile_size).toRaylib(),
        pivot.toRaylib(),
        rot,
        raylib.RED,
    );
}
