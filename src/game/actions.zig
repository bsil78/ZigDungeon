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
        return switch (self) {
            inline else => |case| try case.preview(allocator),
        };
    }
};

pub const ActionPreview = union(enum) {
    move: *MoveActionPreview,
    shoot: *ShootActionPreview,

    pub fn deinit(self: ActionPreview) !void {
        switch (self) {
            inline else => |case| try case.deinit(),
        }
    }
};

/// Action Preview struct. Draw the preview of an actor's action on the map.
pub const MoveActionPreview = struct {
    allocator: Allocator,
    cell_transform: CellTransform,
    sprite: *Sprite,

    pub fn init(allocator: Allocator, direction: Vector2(i16), cell: Vector2(i16), level: *Level) !*MoveActionPreview {
        const ptr = try allocator.create(MoveActionPreview);

        ptr.* = .{
            .allocator = allocator,
            .cell_transform = CellTransform.init(cell, &level.tilemap.transform),
            .sprite = try Sprite.init(
                allocator,
                arrow_texture_path,
                &ptr.cell_transform.transform,
                2,
                Color.red,
            ),
        };

        const dir = direction.floatFromInt(f32);
        ptr.cell_transform.transform.rotation = trigo.radToDeg(f32, dir.angle());
        ptr.sprite.render_trait.tint = Color.red.toRaylib();
        ptr.sprite.pivot = Vector2(f32).initOneValue(16);

        return ptr;
    }

    pub fn deinit(self: *const MoveActionPreview) !void {
        try self.sprite.deinit();
        self.allocator.destroy(self);
    }
};

pub const ActionPreview = struct {
    allocator: Allocator,
    action_area: ActionArea,
    caster: *Actor,
    level: *Level,
    texture_path: ?[]u8,
    render_trait: RenderTrait,    

    pub fn init(allocator: Allocator, area: ActionArea, caster: *Actor, level: *Level, text_path: ?[]u8) !ActionPreview {
        const ptr = try allocator.create(ActionPreview);
        ptr = .{
            .allocator = allocator,
            .action_area = area,
            .caster = caster,
            .level = level,
            .texture_path = text_path,
        };

        return ptr;
    }
};

pub const ShootActionPreview = struct {
    allocator: Allocator,
    direction: Vector2(i16),

    pub fn init(allocator: Allocator, direction: Vector2(i16), caster_cell: Vector2(i16), level: *Level) !*ShootActionPreview {
        const ptr = allocator.create(ShootActionPreview);
        ptr.* = .{
            .allocator = allocator,
            .direction = direction,
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

    pub fn preview(self: *const MoveAction, allocator: Allocator) !ActionPreview {
        const dir: Vector2(i16) = self.to.minus(self.caster.cell_transform.cell);
        return ActionPreview{ .move = try MoveActionPreview.init(allocator, dir, self.to, self.level.tilemap) };
    }
};

pub const ShootAction = struct {
    caster: *Actor,
    direction: Vector2(i16),
    level: *Level,

    pub fn resolve(self: *const ShootAction) !void {
        var buffer: [100]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);
        const action_area = self.getActionArea(fba.allocator());
        const targets = try self.level.getActorsInArea(fba.allocator(), action_area.area_of_effect.?);
        for (targets.items) |target| {
            try target.damage(1);
        }
    }
    
    pub fn preview(self: *const ShootAction) !void {
        
    }
    
    fn getActionArea(self: *const ShootAction, allocator: Allocator) ActionArea {
        const trajectory = ArrayList(Vector2(i16)).init(allocator);

        var current_cell = self.caster.cell_transform.cell.add(self.direction);

        while (try self.level.isCellFree(current_cell)) {
            current_cell = self.caster.cell_transform.cell.add(self.direction);
            trajectory.append(current_cell);
        }

        return .{
            .trajectory = trajectory.items,
            .area_of_effect = null,
            .aoe_origin = current_cell,
        };
    }
};
