// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const engine = @import("../../engine/engine.zig");
const project_settings = @import("../project_settings.zig");
const globals = @import("../globals.zig");
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Vector2 = maths.geometry.vectors.Vector2;
const Tilemap = engine.tiles.Tilemap;
const Tileset = engine.tiles.Tileset;
const Character = @import("../character/character.zig").Character;
const Enemy = @import("../enemy/enemy.zig").Enemy;
const Renderable = @import("../rendering/components.zig").Renderable;
// #endregion


const TileType = enum(usize) {
    Wall=0,
    Ground=1,
    Void=2,
};


pub const GameWorld = struct {
    allocator: Allocator,
    tilemap: *Tilemap,
    tiles: ArrayList(TileType) = undefined,
    character: ?Character = null,
    enemies: ArrayList(Enemy),
    work_buffer: ArrayList(Vector2(i16)),

    // The init function initializes the game world by creating the tilemap, character, and enemies.
    // It also sets up the work buffer for pathfinding and other operations.
    pub fn init(allocator: Allocator) !GameWorld {
        const tileset = try Tileset.initFromSpriteSheet(allocator, globals.assets.tileset);
        const tilemap = try Tilemap.initFromPngData(allocator, globals.assets.level, tileset, tileTypeMapper);
        tilemap.center(.{
            .x = @as(f32,project_settings.window_rect.x),
            .y = @as(f32,project_settings.window_rect.y),
            .w = @as(f32,project_settings.window_rect.w),
            .h = @as(f32,project_settings.window_rect.h),
        });

        const character = try Character.create(allocator, tilemap,Vector2(i16).One());
        var enemies = try ArrayList(Enemy).initCapacity(allocator, 16);
        const enemies_cells = [_]Vector2(i16){ 
            Vector2(i16).init(5, 1), 
            Vector2(i16).init(7, 3), 
            Vector2(i16).init(3, 4) 
        };
        for (enemies_cells) |cell| {
            const enemy = try Enemy.create(allocator, tilemap, cell);
            try enemies.append(allocator, enemy);      
        }

        return .{
            .allocator = allocator,
            .tilemap = tilemap,
            .character = character,
            .enemies = enemies,
            .work_buffer = try ArrayList(Vector2(i16)).initCapacity(allocator, 256),
        };
    }

    // The tileTypeMapper function maps a color value to a corresponding TileType enum value.
    fn tileTypeMapper(color: u32) usize {
        return switch (color) {
            255 => @intFromEnum(TileType.Wall),
            0 => @intFromEnum(TileType.Ground),
            else => @intFromEnum(TileType.Void),
        };
    }

    pub fn deinit(self: *GameWorld) void {
        if (self.character) |*character| character.renderable.destroySprite();
        for (self.enemies.items) |*enemy| enemy.renderable.destroySprite();
        self.enemies.deinit(self.allocator);
        self.work_buffer.deinit(self.allocator);
        self.tilemap.deinit();
    }

    pub fn destroyCharacter(self: *GameWorld) void {
        if (self.character) |*character| character.renderable.destroySprite();
        self.character = null;
    }

    pub fn destroyEnemy(self: *GameWorld, index: usize) void {
        self.enemies.items[index].renderable.destroySprite();
        _ = self.enemies.swapRemove(index);
    }

    // The getTile function retrieves the tile type at a specific cell in the game world.
    // It checks if the cell is within bounds and returns the corresponding TileType enum value.
    pub fn getTile(self: *GameWorld, cell: Vector2(i16)) Tilemap.TilemapError!TileType {
        const tile_type = try self.tilemap.getTile(cell);
        return @enumFromInt(tile_type);
    }

    // The getEnemyAtCell function checks if there is an enemy at the specified cell in the game world.
    pub fn getEnemyAtCell(self: *GameWorld, cell: Vector2(i16)) ?*Enemy {
        for (self.enemies.items) |*enemy| {
            if (enemy.position.cell.equal(&cell)) return enemy;
        }
        return null;
    }

    // The isCellOccupiedByOtherEnemy function checks if a given cell is occupied by any enemy other than the one specified by enemy_index.
    pub fn isCellOccupiedByOtherEnemy(self: *GameWorld, cell: Vector2(i16), enemy_index: usize) bool {
        for (self.enemies.items, 0..) |*enemy, index| {
            if (index != enemy_index and enemy.position.cell.equal(&cell)) return true;
        }
        return false;
    }

    // The isCellOccupied function checks if a given cell is occupied by either the character or any enemy in the game world.
    pub fn isCellOccupied(self: *GameWorld, cell: Vector2(i16)) bool {
        if (self.character) |character| {
            if (character.position.cell.equal(&cell)) return true;
        }
        return self.getEnemyAtCell(cell) != null;
    }

    // The isCellWalkable function checks if a given cell is walkable by verifying that it exists in the tilemap and is of type Ground.
    pub fn isCellWalkable(self: *GameWorld, cell: Vector2(i16)) Tilemap.TilemapError!bool {
        if (!self.tilemap.tileExist(cell)) return Tilemap.TilemapError.OutOfBound;
        const tile_type = try self.getTile(cell);
        return switch (tile_type) {
            TileType.Ground => true,
            else => false,
        };
    }

    // The populateAccessibleCells function populates the work_buffer with all accessible neighboring cells of a given cell.
    // It checks the four cardinal directions (up, down, left, right) and adds any walkable cells to the work_buffer for further processing, such as pathfinding or movement planning.
    pub fn populateAccessibleCells(self: *GameWorld, cell: Vector2(i16)) !void {
        self.work_buffer.clearRetainingCapacity();
        for (Vector2(i16).cardinalDirections()) |direction| {
            const destination = cell.add(&direction);
            if (self.isCellWalkable(destination)) |walkable| {
                if (walkable) try self.work_buffer.append(self.allocator, destination);
            } else |_| {}
        }
    }

};


