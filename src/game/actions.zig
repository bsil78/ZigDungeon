const std = @import("std");
const engine = @import("../engine/engine.zig");
const Actor = @import("../Actor.zig");
const Level = @import("../Level.zig");
const CellTransform = @import("CellTransform.zig");
const Sprite = @import("Sprite.zig");
const trigo = engine.maths.trigo;
const Color = engine.Color;
const Tilemap = engine.tiles.Tilemap;
const Vector2 = engine.maths.Vector2;
const Allocator = std.mem.Allocator;

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

/// Actor action interface
const ActorAction = struct {
    ptr: *anyopaque,
    target_cell: ?Vector2(i16),
    resolve: *const fn (ptr: *anyopaque) anyerror!void,

    pub fn init(ptr: anytype, target_cell: ?Vector2) ActorAction {
        const T = @TypeOf(ptr);
        const ptr_info = @typeInfo(T);

        const gen = struct {
            pub fn resolve(pointer: *anyopaque) anyerror!void {
                const self: T = @ptrCast(@alignCast(pointer));
                return ptr_info.pointer.child.resolve(self);
            }
        };

        return .{
            .ptr = ptr,
            .target_cell = target_cell,
            .resolve = gen.resolve,
        };
    }
};

/// Action Preview struct. Draw the preview of an actor's action on the map.
const ActionPreview = struct {
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
};

const MoveAction = struct {
    caster: *Actor,
    level: *Level,
    to: Vector2(i16),
    
    pub fn actorAction(self: *MoveAction) ActorAction {
        return .{ .ptr = self, .resolve = self.resolve };
    }

    pub fn resolve(self: *MoveAction) !void {
        self.caster.move(self.to);
    }

    pub fn preview(self: *MoveAction, allocator: Allocator) !*ActionPreview {
        return ActionPreview.init(allocator, self.to, self.ActorAction(), self.level.tilemap);
    }
};
