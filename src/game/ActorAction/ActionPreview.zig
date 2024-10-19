const std = @import("std");
const engine = @import("../engine/engine.zig");
const ActorAction = @import("ActorAction.zig");
const Level = @import("Level.zig");
const CellTransform = @import("CellTransform.zig");
const Sprite = engine.sprites.Sprite;
const ActionPreview = @This();

const Color = @import("../engine/color/Color.zig");
const Tilemap = engine.tiles.Tilemap;
const raylib = engine.raylib;
const trigo = engine.maths.trigo;
const Rect = engine.maths.Rect;
const Vector2 = engine.maths.Vector.Vector2;
const Allocator = std.mem.Allocator;

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

allocator: Allocator,
cell_transform: CellTransform,
action: *ActorAction,
sprite: *Sprite,

pub fn init(allocator: Allocator, cell: Vector2(i16), action: *ActorAction, tilemap: *Tilemap) !*ActionPreview {
    const ptr = try allocator.create(ActionPreview);

    ptr.* = .{
        .allocator = allocator,
        .cell_transform = CellTransform.init(cell, &tilemap.transform),
        .action = action,
        .sprite = try Sprite.init(
            allocator,
            arrow_texture_path,
            &ptr.cell_transform.transform,
            2,
            Color.red,
        ),
    };

    const caster = ptr.action.caster;
    const dir = caster.cell_transform.cell.directionTo(&cell);
    ptr.cell_transform.transform.rotation = trigo.radToDeg(f32, dir.angle());

    ptr.sprite.render_trait.tint = Color.red.toRaylib();

    ptr.sprite.pivot = Vector2(f32).initOneValue(16);

    return ptr;
}

pub fn deinit(self: *ActionPreview) !void {
    try self.sprite.deinit();
    self.allocator.destroy(self);
}
