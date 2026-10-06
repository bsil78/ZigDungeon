// #region Namespace imports
const std = @import("std");
const libs = @import("../libs/libs.zig");
const maths = libs.maths;
const pathfinding = maths.algorithms.pathfinding;
const globals = @import("globals.zig");
const enums = @import("game_enums.zig");
const engine = @import("../engine/engine.zig");
// #endregion

// #region Concrete imports
const GameRandom = engine.core.random.GameRandom;
const Transform = engine.core.rendering.Transform;
const Vector2 = maths.geometry.vectors.Vector2;
const Rect = maths.geometry.shapes.Rect;
const Assets = @import("assets/assets.zig").Assets;
const Character = @import("entities/character/character.zig").Character;
const Soldier = @import("entities/npc/soldier/soldier.zig").Soldier;
const Slime = @import("entities/npc/slime/slime.zig").Slime;
const Entity = @import("entities/entity.zig").Entity;
const EntityType = Entity.Type;
const NPCState = @import("entities/npc/generic/npc_plans.zig").NPCState;
const TileType = @import("game_enums.zig").TileType;
const GameResources = @import("game_types.zig").GameResources;
const GameTilesSet = @import("game_types.zig").GameTilesSet;
const GameTilesMap = @import("game_types.zig").GameTilesMap;
const WorldCell = @import("game_types.zig").WorldCell;
// #endregion

const GameWorld = @This();

resources: GameResources = undefined,
entities: [globals.MAX_ENTITIES]?Entity = @splat(null),
tick: u32 = 0,

// Initializes world state using assets owned by the game.
pub fn init(assets: *const Assets, window_rect: Rect(u32)) !GameWorld {
    const tiles_map = try createCenteredTilemap(window_rect);
    const entities = try createStartingEntities(assets, tiles_map.transform);

    return .{
        .resources = .{ .tilesMap = tiles_map },
        .entities = entities,
    };
}

fn createCenteredTilemap(window_rect: Rect(u32)) !GameTilesMap {
    var tiles_map = try Assets.gameTilesMap(enums.LevelId.LEVEL1);
    tiles_map.center(Rect(f32){
        .x = @floatFromInt(window_rect.x),
        .y = @floatFromInt(window_rect.y),
        .w = @floatFromInt(window_rect.w),
        .h = @floatFromInt(window_rect.h),
    }, GameTilesSet.TILE_SIZE);
    return tiles_map;
}

fn createStartingEntities(assets: *const Assets, parent_transform: Transform) ![globals.MAX_ENTITIES]?Entity {
    var entities: [globals.MAX_ENTITIES]?Entity = @splat(null);
    try addCharacter(&entities, assets, parent_transform);
    try addSoldiers(&entities, assets, parent_transform);
    try addSlime(&entities, assets, parent_transform);
    return entities;
}

fn addCharacter(entities: *[globals.MAX_ENTITIES]?Entity, assets: *const Assets, parent_transform: Transform) !void {
    try insertEntity(entities, .{
        .id = globals.CHARACTER_ENTITY_ID,
        .type = EntityType.character,
        .data = .{ .character = Character.init(assets.character_sprite) },
        .cell = WorldCell.One(),
        .health = .{ .hp = 100, .max_hp = 100 },
        .force = 10,
        .parent_transform = parent_transform,
    });
}

fn addSoldiers(entities: *[globals.MAX_ENTITIES]?Entity, assets: *const Assets, parent_transform: Transform) !void {
    const soldier_cells: [2]WorldCell = .{ .{ .x = 5, .y = 1 }, .{ .x = 7, .y = 3 } };
    for (soldier_cells, 0..) |cell, i| {
        const id: globals.EntityId = @intCast(@as(usize, globals.FIRST_SOLDIER_ENTITY_ID) + i);
        try insertEntity(entities, .{
            .id = id,
            .type = EntityType.npc,
            .data = .{ .soldier = Soldier.init(assets.soldier_sprite) },
            .cell = cell,
            .health = .{ .hp = 50, .max_hp = 50 },
            .force = 5,
            .parent_transform = parent_transform,
        });
    }
}

fn addSlime(entities: *[globals.MAX_ENTITIES]?Entity, assets: *const Assets, parent_transform: Transform) !void {
    try insertEntity(entities, .{
        .id = globals.FIRST_SLIME_ENTITY_ID,
        .type = EntityType.npc,
        .data = .{ .slime = try Slime.init(assets.slime_spritesheet) },
        .cell = .{ .x = 2, .y = 4 },
        .health = .{ .hp = 50, .max_hp = 50 },
        .force = 5,
        .parent_transform = parent_transform,
    });
}

pub fn newTick(self: *GameWorld) void {
    self.tick += 1;
}

pub fn deinit(self: *GameWorld) void {
    self.entities = @splat(null);
}

const EntityInsertError = error{ EntityIdOutOfRange, EntitySlotOccupied, InvalidEntitySlot, EntityTypeCapacityExceeded };

fn insertEntity(entities: *[globals.MAX_ENTITIES]?Entity, entity: Entity) EntityInsertError!void {
    const index: usize = entity.id;
    if (index >= entities.len) return EntityInsertError.EntityIdOutOfRange;
    const entity_data_type = entity.entityDataType();
    const valid_type_slot = switch (entity_data_type) {
        .character => entity.id == globals.CHARACTER_ENTITY_ID,
        .soldier => entity.id >= globals.FIRST_SOLDIER_ENTITY_ID and entity.id < globals.FIRST_SLIME_ENTITY_ID,
        .slime => entity.id >= globals.FIRST_SLIME_ENTITY_ID,
    };
    if (!valid_type_slot) {
        return EntityInsertError.InvalidEntitySlot;
    }
    if (entities[index] != null) return EntityInsertError.EntitySlotOccupied;
    var type_count: usize = 0;
    for (entities) |entity_opt| {
        if (entity_opt) |existing| {
            if (existing.entityDataType() == entity_data_type) type_count += 1;
        }
    }
    const type_capacity = switch (entity_data_type) {
        .character => 1,
        .soldier => globals.MAX_SOLDIERS,
        .slime => globals.MAX_SLIMES,
    };
    if (type_count >= type_capacity) return EntityInsertError.EntityTypeCapacityExceeded;
    entities[index] = entity;
}

/// Takes ownership of entity resources only when insertion succeeds.
pub fn addEntity(self: *GameWorld, entity: Entity) EntityInsertError!void {
    try insertEntity(&self.entities, entity);
}

pub fn getEntity(self: *GameWorld, entity_id: globals.EntityId) ?*Entity {
    const index: usize = entity_id;
    if (index >= self.entities.len) return null;
    if (self.entities[index]) |*entity| {
        std.debug.assert(entity.id == entity_id);
        return entity;
    }
    return null;
}

pub fn getCharacter(self: *GameWorld) ?*Entity {
    const entity = self.getEntity(globals.CHARACTER_ENTITY_ID) orelse return null;
    return switch (entity.data) {
        .character => entity,
        else => null,
    };
}

// Retrieves the map's tile value for the cell and converts it to TileType,
// propagating lookup errors.
pub fn getTile(self: *const GameWorld, cell: WorldCell) GameTilesMap.Error!TileType {
    const tile_type = try self.resources.tilesMap.getTile(cell);
    return @enumFromInt(tile_type);
}

pub fn pointedCell(self: *const GameWorld, screen_position: Vector2(f32)) ?WorldCell {
    const map_origin = self.resources.tilesMap.transform.position;
    const cell_size = GameTilesSet.TILE_SIZE.as(f32);
    const position = screen_position.minus(map_origin);
    const map_size = GameTilesMap.SIZE.as(f32);
    const map_width = cell_size.x * map_size.x;
    const map_height = cell_size.y * map_size.y;
    if (position.x < 0 or position.y < 0 or position.x >= map_width or position.y >= map_height) {
        return null;
    }
    return WorldCell.init(
        @intFromFloat(@floor(position.x / cell_size.x)),
        @intFromFloat(@floor(position.y / cell_size.y)),
    );
}

pub fn getEnemyAtCell(self: *const GameWorld, cell: WorldCell) ?globals.EntityId {
    for (&self.entities, 0..) |*entity_opt, index| {
        if (entity_opt.*) |*entity| {
            std.debug.assert(entity.id == index);
            switch (entity.data) {
                .character => {},
                .soldier, .slime => {
                    if (entity.cell.equal(&cell)) return entity.id;
                },
            }
        }
    }
    return null;
}

pub fn isCellOccupiedByOtherEnemy(self: *const GameWorld, cell: WorldCell, entity_id: globals.EntityId) bool {
    for (&self.entities, 0..) |*entity_opt, index| {
        if (entity_opt.*) |*entity| {
            std.debug.assert(entity.id == index);
            switch (entity.data) {
                .character => {},
                .soldier, .slime => {
                    if (entity.id != entity_id and entity.cell.equal(&cell)) return true;
                },
            }
        }
    }
    return false;
}

// The isCellOccupied function checks if a given cell is occupied by either the character or any enemy in the game world.
pub fn isCellOccupied(self: *const GameWorld, cell: WorldCell) bool {
    for (&self.entities, 0..) |*entity_opt, index| {
        if (entity_opt.*) |*entity| {
            std.debug.assert(entity.id == index);
            if (entity.cell.equal(&cell)) return true;
        }
    }
    return false;
}

// Checks whether the map's tile lookup for the cell resolves to Ground.
pub fn isCellWalkable(self: *const GameWorld, cell: WorldCell) GameTilesMap.Error!bool {
    if (!self.resources.tilesMap.tileExist(cell)) return GameTilesMap.Error.OutOfBound;
    const tile_type = try self.getTile(cell);
    return switch (tile_type) {
        TileType.Ground => true,
        else => false,
    };
}

fn checkBoundsAndCast(destination: Vector2(i16)) ?WorldCell {
    if (destination.x < 0) return null;
    if (destination.x >= globals.WORLD_SIZE.x) return null;
    if (destination.y < 0) return null;
    if (destination.y >= globals.WORLD_SIZE.y) return null;
    return destination.as(globals.WORLD_SIZE_SCALAR);
}

// Returns up to four in-bounds, walkable cardinal neighbors of the given cell.
pub fn getAccessibleCells(self: *const GameWorld, cell: WorldCell) ![4]?WorldCell {
    var cells: [4]?WorldCell = undefined;
    @memset(&cells, null);
    var i: u3 = 0;
    for (Vector2(i16).cardinalDirections()) |direction| {
        const destination = checkBoundsAndCast(cell.as(i16).add(direction));
        const destination_cell = destination orelse continue;
        if (try self.isCellWalkable(destination_cell)) {
            cells[i] = destination_cell;
            i = i + 1;
        }
    }
    return cells;
}

// Returns walkable cardinal neighbors that are not occupied by another enemy.
pub fn getEnemyFreeAccessibleCells(self: *const GameWorld, cell: WorldCell, entity_id: globals.EntityId) ![4]?WorldCell {
    var cells: [4]?WorldCell = undefined;
    @memset(&cells, null);
    var i: u3 = 0;
    for (Vector2(i16).cardinalDirections()) |direction| {
        const destination = checkBoundsAndCast(cell.as(i16).add(direction));
        const destination_cell = destination orelse continue;
        if (try self.isCellWalkable(destination_cell) and !self.isCellOccupiedByOtherEnemy(destination_cell, entity_id)) {
            cells[i] = destination_cell;
            i = i + 1;
        }
    }
    return cells;
}

pub fn getCharacterDistances(self: *GameWorld) ![globals.WORLD_LEN]u8 {
    const size = @TypeOf(self.resources.tilesMap).SIZE;
    const character = self.getCharacter() orelse return error.CharacterMissing;
    const distances: [globals.WORLD_LEN]u8 = try pathfinding.breadthFirstDistances(
        globals.WORLD_LEN,
        WorldCell,
        character.cell,
        @intCast(size.x),
        @intCast(size.y),
        @constCast(self),
        isPathfindingCellWalkable,
    );
    return distances;
}

pub fn updateAnimations(self: *GameWorld) void {
    for (&self.entities) |*entity_opt| {
        if (entity_opt.*) |*entity| {
            switch (entity.data) {
                .character, .soldier => {},
                .slime => |*slime| slime.update(),
            }
        }
    }
}

pub fn damageEnemy(self: *GameWorld, entity_id: globals.EntityId, amount: u16) bool {
    const entity = self.getEntity(entity_id) orelse return false;
    if (entity.entityType() == .character) return false;
    entity.health.reduceBy(amount);
    return true;
}

// interface fonction for BFS algorithm
fn isPathfindingCellWalkable(context: *anyopaque, cell: WorldCell) bool {
    const world: *GameWorld = @ptrCast(@alignCast(context));
    return world.isCellWalkable(cell) catch false;
}

pub fn destroyEntity(self: *GameWorld, entity_id: globals.EntityId) void {
    std.debug.assert(self.getEntity(entity_id)!=null);
    self.entities[@intCast(entity_id)] = null;
}
