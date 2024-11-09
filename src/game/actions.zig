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

    pub fn preview(self: *const ActorAction, allocator: Allocator) !*ActionPreview {
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
        const ptr = try allocator.create(ShootAction);
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
        try trajectory.append(current_cell);

        while (try self.level.isCellWalkable(current_cell)) {
            current_cell = current_cell.add(self.direction);
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
    action: *const ActorAction,
    cells: ?ArrayList(*PreviewCell) = null,

    pub fn init(allocator: Allocator, actor_action: *const ActorAction) !*ActionPreview {
        var ptr = try allocator.create(ActionPreview);
        ptr.* = .{
            .allocator = allocator,
            .action = actor_action,
        };

        ptr.cells = try ptr.generatePreviewCells(allocator, actor_action.getActionArea());
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

        const trajectory_color = Color.init(255, 0, 0, 127);
        const color: Color, const texture_path: ?[]const u8 = switch (self.action.*) {
            .move => .{ Color.blue, arrow_texture_path },
            else => .{ Color.red, null },
        };

        if (area.trajectory) |trajectory| {
            for (trajectory.items) |cell| {
                const preview_cell = try PreviewCell.init(self.allocator, cell, trajectory_color, self.action.getLevel(), texture_path);
                try cells.append(preview_cell);
            }
        }

        for (area.area_of_effect.?.items) |cell| {
            var preview_cell = try PreviewCell.init(self.allocator, cell, color, self.action.getLevel(), texture_path);

            switch (self.action.*) {
                TagActorAction.move => {
                    const caster = self.action.getCaster();
                    const caster_cell = caster.cell_transform.cell;
                    const dest_cell = area.aoe_origin.?;
                    var dir = dest_cell.minus(caster_cell).floatFromInt(f32);
                    preview_cell.cell_transform.transform.rotation = dir.angle();
                },
                else => {},
            }

            try cells.append(preview_cell);
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
            ptr.sprite = try Sprite.init(allocator, path, &ptr.cell_transform.transform, 1, Color.white);
            var sprite = ptr.sprite.?;
            sprite.pivot = sprite.size.divide(2.0);
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
