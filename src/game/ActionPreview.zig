const std = @import("std");
const engine = @import("../engine/engine.zig");
const ActorAction = @import("ActorAction.zig");
const Level = @import("Level.zig");
const CellTransform = @import("CellTransform.zig");
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
        .sprite = try Sprite.init(
            allocator,
            arrow_texture_path,
            &action.cell_transform.transform,
            2,
        ),
    };

    const dir = ptr.action.caster.cell_transform.cell.directionTo(&cell);
    ptr.action.cell_transform.transform.rotation = trigo.radToDeg(f32, dir.angle());

    ptr.sprite.pivot = Vector2(f32).initOneValue(16);

    return ptr;
}

pub fn deinit(self: *ActionPreview) !void {
    try self.sprite.deinit();
    self.allocator.destroy(self);
}
