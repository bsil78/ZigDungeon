const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const maths = @import("../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const Transform = maths.geometry.Transform;

const datastructs = @import("../libs/datastructs/datastructs.zig");

const engine = @import("../engine/engine.zig");

const Sprite = engine.sprites.Sprite;
const Tilemap = engine.tiles.Tilemap;
const EntityID = engine.core.EntityID;
const NULL_ENTITY = engine.core.NULL_ENTITY;

const components = @import("components.zig");

const PositionStorage = datastructs.SparseDenseSet(components.Position, EntityID);
const LocalTransformStorage = datastructs.SparseDenseSet(components.LocalTransform, EntityID);
const WorldTransformStorage = datastructs.SparseDenseSet(components.WorldTransform, EntityID);
const HealthStorage = datastructs.SparseDenseSet(components.Health, EntityID);
const ActorStorage = datastructs.SparseDenseSet(components.Actor, EntityID);
const RenderableStorage = datastructs.SparseDenseSet(components.Renderable, EntityID);
const InputableStorage = datastructs.SparseDenseSet(components.Inputable, EntityID);
const ProcessableStorage = datastructs.SparseDenseSet(components.Processable, EntityID);

pub const GameWorld = struct {
    allocator: Allocator,
    tilemap: *Tilemap,

    positions: PositionStorage,
    local_transforms: LocalTransformStorage,
    world_transforms: WorldTransformStorage,
    healths: HealthStorage,
    actors: ActorStorage,
    renderables: RenderableStorage,
    inputables: InputableStorage,
    processables: ProcessableStorage,

    sprites: std.AutoHashMap(EntityID, components.SpriteData),
    action_plans: std.AutoHashMap(EntityID, components.ActionPlan),

    work_buffer: ArrayList(Vector2(i16)),

    entities: ArrayList(EntityID),
    next_entity_id: EntityID = 1,

    pub fn init(allocator: Allocator, tilemap: *Tilemap) !GameWorld {
        return GameWorld{
            .allocator = allocator,
            .tilemap = tilemap,
            .positions = try PositionStorage.init(allocator),
            .local_transforms = try LocalTransformStorage.init(allocator),
            .world_transforms = try WorldTransformStorage.init(allocator),
            .healths = try HealthStorage.init(allocator),
            .actors = try ActorStorage.init(allocator),
            .renderables = try RenderableStorage.init(allocator),
            .inputables = try InputableStorage.init(allocator),
            .processables = try ProcessableStorage.init(allocator),
            .sprites = std.AutoHashMap(EntityID, components.SpriteData).init(allocator),
            .action_plans = std.AutoHashMap(EntityID, components.ActionPlan).init(allocator),
            .work_buffer = try ArrayList(Vector2(i16)).initCapacity(allocator, 256),
            .entities = try ArrayList(EntityID).initCapacity(allocator, 32),
        };
    }

    pub fn deinit(self: *GameWorld) void {
        self.positions.deinit();
        self.local_transforms.deinit();
        self.world_transforms.deinit();
        self.healths.deinit();
        self.actors.deinit();
        self.sprites.deinit();
        self.action_plans.deinit();
        self.renderables.deinit();
        self.inputables.deinit();
        self.processables.deinit();
        self.entities.deinit(self.allocator);
        self.work_buffer.deinit(self.allocator);
        self.tilemap.deinit();
    }

    pub fn createEntity(self: *GameWorld) !EntityID {
        const id = self.next_entity_id;
        self.next_entity_id += 1;
        try self.entities.append(self.allocator, id);
        return id;
    }

    pub fn destroyEntity(self: *GameWorld, id: EntityID) void {
        var remove_idx: ?usize = null;
        for (self.entities.items, 0..) |eid, i| {
            if (eid == id) {
                remove_idx = i;
                break;
            }
        }
        if (remove_idx) |idx| {
            _ = self.entities.swapRemove(idx);
        }

        _ = self.positions.remove(id);
        _ = self.local_transforms.remove(id);
        _ = self.world_transforms.remove(id);
        _ = self.healths.remove(id);
        _ = self.actors.remove(id);
        _ = self.sprites.remove(id);
        _ = self.action_plans.remove(id);
        _ = self.renderables.remove(id);
        _ = self.inputables.remove(id);
        _ = self.processables.remove(id);
    }

    pub fn getPosition(self: *const GameWorld, id: EntityID) ?*const components.Position {
        return self.positions.get(id);
    }

    pub fn getPositionMut(self: *GameWorld, id: EntityID) ?*components.Position {
        return self.positions.getMut(id);
    }

    pub fn setPosition(self: *GameWorld, id: EntityID, pos: components.Position) !void {
        try self.positions.set(id, pos);
    }

    pub fn getLocalTransform(self: *const GameWorld, id: EntityID) ?*const components.LocalTransform {
        return self.local_transforms.get(id);
    }

    pub fn getLocalTransformMut(self: *GameWorld, id: EntityID) ?*components.LocalTransform {
        return self.local_transforms.getMut(id);
    }

    pub fn setLocalTransform(self: *GameWorld, id: EntityID, local: components.LocalTransform) !void {
        try self.local_transforms.set(id, local);
    }

    pub fn getWorldTransform(self: *const GameWorld, id: EntityID) ?*const components.WorldTransform {
        return self.world_transforms.get(id);
    }

    pub fn getWorldTransformMut(self: *GameWorld, id: EntityID) ?*components.WorldTransform {
        return self.world_transforms.getMut(id);
    }

    pub fn setWorldTransform(self: *GameWorld, id: EntityID, world: components.WorldTransform) !void {
        try self.world_transforms.set(id, world);
    }

    pub fn getHealth(self: *const GameWorld, id: EntityID) ?*const components.Health {
        return self.healths.get(id);
    }

    pub fn getHealthMut(self: *GameWorld, id: EntityID) ?*components.Health {
        return self.healths.getMut(id);
    }

    pub fn getActor(self: *const GameWorld, id: EntityID) ?*const components.Actor {
        return self.actors.get(id);
    }

    pub fn getActorMut(self: *GameWorld, id: EntityID) ?*components.Actor {
        return self.actors.getMut(id);
    }

    pub fn getSprite(self: *const GameWorld, id: EntityID) ?*const components.SpriteData {
        return self.sprites.getPtr(id);
    }

    pub fn getActionPlan(self: *const GameWorld, id: EntityID) ?*const components.ActionPlan {
        return self.action_plans.getPtr(id);
    }

    pub fn getActionPlanMut(self: *GameWorld, id: EntityID) ?*components.ActionPlan {
        return self.action_plans.getPtr(id);
    }

    pub fn setHealth(self: *GameWorld, id: EntityID, health: components.Health) !void {
        try self.healths.set(id, health);
    }

    pub fn setActor(self: *GameWorld, id: EntityID, actor: components.Actor) !void {
        try self.actors.set(id, actor);
    }

    pub fn setSprite(self: *GameWorld, id: EntityID, sprite: components.SpriteData) !void {
        try self.sprites.put(id, sprite);
    }

    pub fn setActionPlan(self: *GameWorld, id: EntityID, plan: components.ActionPlan) !void {
        try self.action_plans.put(id, plan);
    }

    pub fn getRenderable(self: *const GameWorld, id: EntityID) ?*const components.Renderable {
        return self.renderables.get(id);
    }

    pub fn getRenderableMut(self: *GameWorld, id: EntityID) ?*components.Renderable {
        return self.renderables.getMut(id);
    }

    pub fn setRenderable(self: *GameWorld, id: EntityID, renderable: components.Renderable) !void {
        try self.renderables.set(id, renderable);
    }

    pub fn removeRenderable(self: *GameWorld, id: EntityID) void {
        self.renderables.remove(id);
    }

    pub fn hasInputable(self: *const GameWorld, id: EntityID) bool {
        return self.inputables.contains(id);
    }

    pub fn addInputable(self: *GameWorld, id: EntityID) !void {
        try self.inputables.set(id, .{});
    }

    pub fn removeInputable(self: *GameWorld, id: EntityID) void {
        self.inputables.remove(id);
    }

    pub fn hasProcessable(self: *const GameWorld, id: EntityID) bool {
        return self.processables.contains(id);
    }

    pub fn addProcessable(self: *GameWorld, id: EntityID) !void {
        try self.processables.set(id, .{});
    }

    pub fn removeProcessable(self: *GameWorld, id: EntityID) void {
        self.processables.remove(id);
    }

    pub fn getAllWithPosition(self: *const GameWorld) []const EntityID {
        return self.entities.items;
    }

    pub fn getEntityAtCell(self: *const GameWorld, cell: Vector2(i16)) ?EntityID {
        for (self.entities.items) |id| {
            if (self.getPosition(id)) |pos| {
                if (pos.cell.equal(&cell)) return id;
            }
        }
        return null;
    }

    pub fn getEntitiesInArea(self: *GameWorld, allocator: Allocator, area: []Vector2(i16)) !ArrayList(EntityID) {
        var result = try ArrayList(EntityID).initCapacity(allocator, 16);
        for (area) |cell| {
            if (self.getEntityAtCell(cell)) |id| {
                try result.append(allocator, id);
            }
        }
        return result;
    }

    pub fn isCellWalkable(self: *const GameWorld, cell: Vector2(i16)) Tilemap.TilemapError!bool {
        const is_valid = !self.tilemap.tileExist(cell);
        if (!is_valid) return Tilemap.TilemapError.OutOfBound;

        const is_walkable = try self.tilemap.isCellWalkable(cell);
        const is_empty = self.getEntityAtCell(cell) == null;

        return is_walkable and is_empty;
    }

    pub fn getAccessibleCells(self: *const GameWorld, allocator: Allocator, cell: Vector2(i16)) !ArrayList(Vector2(i16)) {
        var result = try ArrayList(Vector2(i16)).initCapacity(allocator, 8);

        for (Vector2(i16).cardinalDirections()) |dir| {
            const dest_cell = cell.add(&dir);
            if (self.isCellWalkable(dest_cell)) |ok| {
                if (ok) try result.append(allocator, dest_cell);
            } else |_| {
            }
        }

        return result;
    }

    pub fn populateAccessibleCells(self: *GameWorld, cell: Vector2(i16)) !void {
        self.work_buffer.clearRetainingCapacity();

        for (Vector2(i16).cardinalDirections()) |dir| {
            const dest_cell = cell.add(&dir);
            if (self.isCellWalkable(dest_cell)) |ok| {
                if (ok) try self.work_buffer.append(self.allocator, dest_cell);
            } else |_| {
            }
        }
    }
};
