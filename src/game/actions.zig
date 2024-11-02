const std = @import("std");
const engine = @import("../engine/engine.zig");
const Actor = @import("Actor.zig");
const Level = @import("Level.zig");
const CellTransform = @import("CellTransform.zig");
const Sprite = engine.sprites.Sprite;
const trigo = engine.maths.trigo;
const Color = engine.Color;
const Tilemap = engine.tiles.Tilemap;
const Vector2 = engine.maths.Vector2;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const RenderTrait = engine.traits.RenderTrait;

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

pub const TagActorAction = enum {
    move,
    shoot,
};

const ActionArea = struct {
    trajectory: ?[]Vector2(i16),
    area_of_effect: ?[]Vector2(i16),
    aoe_origin: ?Vector2(i16),
};

pub const ActorAction = union(TagActorAction) {
    move: MoveAction,
    shoot: ShootAction,

    pub fn resolve(self: ActorAction) !void {
        switch (self) {
            inline else => |case| try case.resolve(),
        }
    }

    pub fn preview(self: ActorAction, allocator: Allocator) !ActionPreview {
        return ActionPreview.init(allocator, self);
    }

    pub fn getCaster(self: ActorAction) *Actor {
        return switch (self) {
            inline else => |case| try case.caster,
        };
    }

    pub fn getLevel(self: ActorAction) *Level {
        return switch (self) {
            inline else => |case| try case.level,
        };
    }

    pub fn getActionArea(self: ActorAction) !ActionArea {
        return switch (self) {
            inline else => |case| try case.getActionArea(),
        };
    }
};

pub const MoveAction = struct {
    caster: *Actor,
    to: Vector2(i16),
    level: *Level,

    pub fn resolve(self: *const MoveAction) !void {
        self.caster.move(self.to);
    }

    pub fn toActorAction(self: *const MoveAction) ActorAction {
        return ActorAction{ .move = self };
    }
};

pub const ShootAction = struct {
    caster: *Actor,
    direction: Vector2(i16),
    level: *Level,

    pub fn resolve(self: *const ShootAction) !void {
        var buffer: [100]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const action_area = try self.getActionArea(fba.allocator());
        const targets = try self.level.getActorsInArea(fba.allocator(), action_area.area_of_effect.?);
        for (targets.items) |target| {
            try target.damage(1);
        }
    }

    pub fn getActionArea(self: *const ShootAction, allocator: Allocator) !ActionArea {
        var trajectory = ArrayList(Vector2(i16)).init(allocator);

        var current_cell = self.caster.cell_transform.cell.add(self.direction);

        while (try self.level.isCellFree(current_cell)) {
            current_cell = self.caster.cell_transform.cell.add(self.direction);
            try trajectory.append(current_cell);
        }

        return .{
            .trajectory = trajectory.items,
            .area_of_effect = null,
            .aoe_origin = current_cell,
        };
    }

    pub fn toActorAction(self: *const ShootAction) ActorAction {
        return ActorAction{ .shoot = self };
    }
};

pub const ActionPreview = struct {
    allocator: Allocator,
    caster: *Actor,
    level: *Level,
    texture_path: ?[]u8 = null,
    cells: ArrayList(*PreviewCell),

    pub fn init(allocator: Allocator, actor_action: ActorAction) !ActionPreview {
        const ptr = try allocator.create(ActionPreview);
        ptr = .{
            .allocator = allocator,
            .caster = actor_action.getCaster(),
            .level = actor_action.getLevel(),
            .cells = try ptr.generatePreviewCells(allocator, try actor_action.getActionArea()),
        };

        return ptr;
    }

    fn generatePreviewCells(self: *ActionPreview, allocator: Allocator, area: ActionArea) !?ArrayList(*PreviewCell) {
        var cells = ArrayList(*PreviewCell).init(allocator);
        for (area.area_of_effect) |cell| {
            try cells.append(try PreviewCell.init(self.allocator, cell, Color.red, self.level, null));
        }
    }

    pub fn deinit() !void {}
};

const PreviewCell = struct {
    cell_transform: CellTransform,
    color: Color,
    texture_path: ?[]const u8,
    sprite: Sprite,
    render_trait: RenderTrait,

    pub fn init(allocator: Allocator, cell: Vector2(i16), color: Color, level: *Level, texture_path: ?[]const u8) !*PreviewCell {
        const ptr = try allocator.create(PreviewCell);
        ptr = .{
            .cell_transform = CellTransform.init(cell, level.tilemap.transform),
            .color = Color,
            .texture_path = texture_path,
            .sprite = try Sprite.init(allocator, texture_path, level.tilemap.transform, 1, Color.white),
            .render_trait = RenderTrait.init(allocator, ptr, 0, color),
        };

        return ptr;
    }
};
