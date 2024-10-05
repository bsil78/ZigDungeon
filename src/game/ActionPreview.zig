const std = @import("std");
const engine = @import("../engine/engine.zig");
const ActorAction = @import("ActorAction.zig");
const Level = @import("Level.zig");
const Sprite = engine.sprites.Sprite;
const ActionPreview = @This();

const Tilemap = engine.tiles.Tilemap;
const raylib = engine.raylib;
const trigo = engine.maths.trigo;
const Rect = engine.maths.Rect;
const Vector2 = engine.maths.Vector.Vector2;
const Allocator = std.mem.Allocator;

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

allocator: Allocator,
cell: Vector2(i16),
action: *ActorAction,
sprite: *Sprite,

pub fn init(allocator: Allocator, cell: Vector2(i16), action: *ActorAction) !*ActionPreview {
    const ptr = try allocator.create(ActionPreview);

    ptr.* = .{
        .allocator = allocator,
        .cell = cell,
        .action = action,
        .sprite = try Sprite.init(allocator, arrow_texture_path, null, 2),
    };

    return ptr;
}

pub fn deinit(self: *ActionPreview) !void {
    try self.sprite.deinit();
    self.allocator.destroy(self);
}

pub fn draw(self: *const ActionPreview, level: *Level) void {
    const cell = self.action.target_cell.?;
    const f_tile_size: f32 = @floatFromInt(Tilemap.tile_size);
    const tile_size = Vector2(f32).One().times(f_tile_size);
    const dir = self.action.caster.cell.directionTo(&cell);
    const rot = trigo.radToDeg(f32, dir.angle());
    const pivot = tile_size.divide(2.0);
    const pos = cell.toFloatV(f32).times(&tile_size).add(&level.tilemap.transform.position).add(&pivot);

    raylib.DrawTexturePro(
        self.arrow_texture,
        Rect(f32).initV(Vector2(f32).Zero(), tile_size).toRaylib(),
        Rect(f32).initV(pos, tile_size).toRaylib(),
        pivot.toRaylib(),
        rot,
        raylib.RED,
    );
}
