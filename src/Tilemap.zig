const std = @import("std");
const raylib = @import("raylib.zig");
const Tileset = @import("Tileset.zig");
const Vector = @import("Vector.zig");
const Rect = @import("Rect.zig").Rect;
const Tilemap = @This();

const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Vector2 = Vector.Vector2;

const TileType = enum(u16) {
    Wall,
    Ground,
    Void,
};

pub const TilemapError = error{OutOfBound};

pub const tile_size = 32;

position: Vector2(f32) = Vector2(f32).Zero(),
tileset: Tileset,
tiles: ArrayList(TileType) = undefined,
grid_width: u32 = 0,
grid_height: u32 = 0,

pub fn initFromPngFile(file_path: []const u8, tileset: Tileset, arena: *ArenaAllocator) !Tilemap {
    const image = raylib.LoadImage(file_path.ptr);
    var tilemap = Tilemap{ .tileset = tileset };

    tilemap.tiles = ArrayList(TileType).init(arena.allocator());
    tilemap.grid_height = @intCast(image.height);
    tilemap.grid_width = @intCast(image.width);

    for (0..tilemap.grid_height) |column| {
        for (0..tilemap.grid_width) |row| {
            const color: raylib.struct_Color = raylib.GetImageColor(image, @intCast(row), @intCast(column));
            const tile = if (color.r == 0.0) TileType.Ground else TileType.Wall;
            try tilemap.tiles.append(tile);
        }
    }

    return tilemap;
}

// Print all the TileType of the tilemap in a grid like fashion
pub fn print(self: Tilemap) void {
    for (self.tiles.items, 0..) |tile, i| {
        if (i % self.grid_width == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{s:^10}", .{@tagName(tile)});
    }

    std.debug.print("\n", .{});
}

// Draw all the tiles of the tilemap
pub fn draw(self: Tilemap) !void {
    for (self.tiles.items, 0..) |tile, i| {
        const row: f32 = @floatFromInt(i % self.grid_width);
        const col: f32 = @floatFromInt(i / self.grid_width);
        const w: f32 = @floatFromInt(self.tileset.tile_width);
        const h: f32 = @floatFromInt(self.tileset.tile_height);
        const pos = Vector2(f32).init(self.position.x + row * w, self.position.y + col * h);
        const tile_index: usize = @intCast(@intFromEnum(tile));

        try self.tileset.drawTile(tile_index, pos);
    }
}

// Get the rect in pixels encapsulating of all the tiles in the tilemap
pub fn getRect(self: Tilemap) Rect(f32) {
    const tile_width: f32 = @floatFromInt(self.tileset.tile_width);
    const tile_height: f32 = @floatFromInt(self.tileset.tile_height);
    const grid_width: f32 = @floatFromInt(self.grid_width);
    const grid_height: f32 = @floatFromInt(self.grid_height);

    return Rect(f32).init(
        self.position.x,
        self.position.y,
        grid_width * tile_width,
        grid_height * tile_height,
    );
}

// Move this Tilemap so it is centered inside the given container rect
pub fn center(self: *Tilemap, container_rect: Rect(f32)) void {
    const rect = self.getRect();
    const centered_rect = rect.centerRect(container_rect);

    self.position = centered_rect.getRectPosition();
}

pub fn isCellWalkable(self: Tilemap, cell: Vector2(i16)) TilemapError!bool {
    const tile_type = try self.getTile(cell);

    return switch (tile_type) {
        TileType.Ground => true,
        else => false,
    };
}

pub fn getTile(self: Tilemap, cell: Vector2(i16)) TilemapError!TileType {
    const tile_id = try self.getTileId(cell);
    return self.tiles.items[tile_id];
}

fn getTileId(self: Tilemap, cell: Vector2(i16)) TilemapError!usize {
    const width: i16 = @intCast(self.grid_width);
    const id = cell.y * width + cell.x;

    if (id >= self.tiles.items.len) {
        return TilemapError.OutOfBound;
    }

    return @intCast(id);
}

pub fn tileExist(self: Tilemap, cell: Vector2(i16)) bool {
    const width: i16 = @intCast(self.grid_width);
    const id = cell.y * width + cell.x;
    return id >= self.tiles.items.len;
}
