const std = @import("std");
const engine = @import("../engine/engine.zig");
const Actor = @import("Actor.zig");
const Level = @import("Level.zig");
const CellTransform = @import("CellTransform.zig");
const globals = @import("globals.zig");
const Sprite = engine.sprites.Sprite;
const trigo = engine.maths.trigo;
const Color = engine.Color;
const Tilemap = engine.tiles.Tilemap;
const Vector2 = engine.maths.Vector2;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const RenderTrait = engine.traits.RenderTrait;
const raylib = engine.raylib;

const arrow_texture_path = "sprites/ui/EnemyActions/Arrow.png";

pub const TagActorAction = enum {
    move,
    shoot,
};

const ActionArea = struct {
    trajectory: ?ArrayList(Vector2(i16)) = null,
    area_of_effect: ?ArrayList(Vector2(i16)) = null,
    aoe_origin: ?Vector2(i16) = null,

    pub fn deinit(self: *ActionArea) void {
        if (self.trajectory) |traj| {
            traj.deinit();
        }

        if (self.area_of_effect) |aoe| {
            aoe.deinit();
        }
    }
};

pub const ActorAction = union(TagActorAction) {
    move: *MoveAction,
    shoot: *ShootAction,

    pub fn resolve(self: ActorAction) !void {
        switch (self) {
            inline else => |case| try case.resolve(),
        }
    }

    pub fn preview(self: ActorAction, allocator: Allocator) !*ActionPreview {
        return try ActionPreview.init(allocator, self);
    }

    pub fn getCaster(self: ActorAction) *Actor {
        return switch (self) {
            inline else => |case| case.caster,
        };
    }

    pub fn getLevel(self: ActorAction) *Level {
        return switch (self) {
            inline else => |case| case.level,
        };
    }

    pub fn getActionArea(self: ActorAction) *const ActionArea {
        return switch (self) {
            inline else => |case| &case.action_area,
        };
    }
};

pub const MoveAction = struct {
    caster: *Actor,
    level: *Level,
    action_area: ActionArea = undefined,

    pub fn init(allocator: Allocator, caster: *Actor, level: *Level, to: Vector2(i16)) !*MoveAction {
        const ptr = try allocator.create(MoveAction);
        ptr.* = .{
            .caster = caster,
            .level = level,
            .action_area = try generateActionArea(allocator, to),
        };
        return ptr;
    }

    pub fn resolve(self: *const MoveAction) !void {
        self.caster.move(self.action_area.aoe_origin.?);
    }

    fn generateActionArea(allocator: Allocator, to: Vector2(i16)) !ActionArea {
        var action_area = ActionArea{
            .aoe_origin = to,
            .area_of_effect = ArrayList(Vector2(i16)).init(allocator),
        };
        try action_area.area_of_effect.?.append(to);
        return action_area;
    }
};

pub const ShootAction = struct {
    caster: *Actor,
    direction: Vector2(i16),
    level: *Level,
    action_area: ActionArea = undefined,

    pub fn init(allocator: Allocator, caster: *Actor, level: *Level, direction: Vector2(i16)) !*ShootAction {
        const ptr = allocator.create(ShootAction);
        ptr.* = .{
            .caster = caster,
            .level = level,
            .direction = direction,
            .action_area = try ptr.generateActionArea(allocator),
        };
        return ptr;
    }

    pub fn resolve(self: *const ShootAction) !void {
        var buffer: [100]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const targets = try self.level.getActorsInArea(fba.allocator(), self.action_area.area_of_effect.?.items);
        for (targets.items) |target| {
            try target.damage(1);
        }
    }

    fn generateActionArea(self: *const ShootAction, allocator: Allocator) !ActionArea {
        var trajectory = ArrayList(Vector2(i16)).init(allocator);

        var current_cell = self.caster.cell_transform.cell.add(self.direction);

        while (try self.level.isCellFree(current_cell)) {
            current_cell = self.caster.cell_transform.cell.add(self.direction);
            try trajectory.append(current_cell);
        }
        var aoe = ArrayList(Vector2(i16)).init(allocator);
        try aoe.append(current_cell);

        return .{
            .trajectory = trajectory,
            .aoe_origin = current_cell,
            .area_of_effect = aoe,
        };
    }
};

pub const ActionPreview = struct {
    allocator: Allocator,
    caster: *Actor,
    level: *Level,
    texture_path: ?[]u8 = null,
    cells: ?ArrayList(*PreviewCell),

    pub fn init(allocator: Allocator, actor_action: ActorAction) !*ActionPreview {
        const ptr = try allocator.create(ActionPreview);
        ptr.* = .{
            .allocator = allocator,
            .caster = actor_action.getCaster(),
            .level = actor_action.getLevel(),
            .cells = try ptr.generatePreviewCells(allocator, actor_action.getActionArea()),
        };

        return ptr;
    }

    pub fn deinit(self: *ActionPreview) !void {
        if (self.cells) |cells| {
            for (cells.items) |cell| {
                try cell.deinit();
            }
        }
        self.allocator.destroy(self);
    }

    fn generatePreviewCells(self: *ActionPreview, allocator: Allocator, area: *const ActionArea) !?ArrayList(*PreviewCell) {
        var cells = ArrayList(*PreviewCell).init(allocator);
        for (area.area_of_effect.?.items) |cell| {
            try cells.append(try PreviewCell.init(self.allocator, cell, Color.red, self.level, null));
        }
        return cells;
    }
};

const PreviewCell = struct {
    cell_transform: CellTransform,
    color: Color,
    texture_path: ?[]const u8,
    sprite: ?*Sprite = null,
    render_trait: *RenderTrait,
    allocator: Allocator,

    pub fn init(allocator: Allocator, cell: Vector2(i16), color: Color, level: *Level, texture_path: ?[]const u8) !*PreviewCell {
        const ptr = try allocator.create(PreviewCell);
        ptr.* = .{
            .allocator = allocator,
            .cell_transform = CellTransform.init(cell, &level.tilemap.transform),
            .color = color,
            .texture_path = texture_path,
            .render_trait = try RenderTrait.init(allocator, ptr, 0, color),
        };

        if (texture_path) |path| {
            ptr.sprite = try Sprite.init(allocator, path, &level.tilemap.transform, 1, Color.white);
        }

        return ptr;
    }

    pub fn deinit(self: *PreviewCell) !void {
        try self.render_trait.deinit();
        if (self.sprite) |sprite| try sprite.deinit();
        self.allocator.destroy(self);
    }

    pub fn render(self: *PreviewCell) void {
        const pos = self.cell_transform.transform.toGlobal().position.intFromFloat(i16);
        const tile_size = globals.tile_size;
        raylib.DrawRectangle(pos.x, pos.y, tile_size.x, tile_size.y, self.color.toRaylib());
    }
};
