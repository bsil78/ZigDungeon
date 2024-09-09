const std = @import("std");
const raylib = @import("raylib.zig");
const Tileset = @import("Tileset.zig");
const Vector = @import("Vector.zig");
const Rect = @import("Rect.zig");
const Tilemap = @This();

const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Vector2 = Vector.Vector2;
const Rect2 = Rect.Rect2;

const TileTypes = enum(u16) {
    Wall,
    Ground,
};

const tile_size = 16;

position: Vector2 = Vector.Vector2Zero,
tileset: Tileset,
tiles: ArrayList(TileTypes) = undefined,
grid_width: u32 = 0,
grid_height: u32 = 0,

pub fn initFromPngFile(file_path: []const u8, tileset: Tileset, arena: *ArenaAllocator) !Tilemap {
    const image = raylib.LoadImage(file_path.ptr);
    var tilemap = Tilemap{ .tileset = tileset };

    tilemap.tiles = ArrayList(TileTypes).init(arena.allocator());
    tilemap.grid_height = @intCast(image.height);
    tilemap.grid_width = @intCast(image.width);

    for (0..tilemap.grid_height) |column| {
        for (0..tilemap.grid_width) |row| {
            const color: raylib.struct_Color = raylib.GetImageColor(image, @intCast(row), @intCast(column));
            const tile = if (color.r == 0.0) TileTypes.Ground else TileTypes.Wall;
            try tilemap.tiles.append(tile);
        }
    }

    return tilemap;
}

pub fn print(self: Tilemap) void {
    for (self.tiles.items, 0..) |tile, i| {
        if (i % self.grid_width == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{s:^10}", .{@tagName(tile)});
    }

    std.debug.print("\n", .{});
}

pub fn draw(self: Tilemap) !void {
    for (self.tiles.items, 0..) |tile, i| {
        const row: f32 = @floatFromInt(i % self.grid_width);
        const col: f32 = @floatFromInt(i / self.grid_width);
        const w: f32 = @floatFromInt(self.tileset.tile_width);
        const h: f32 = @floatFromInt(self.tileset.tile_height);
        const pos = Vector2{ .x = self.position.x + row * w, .y = self.position.y + col * h };
        const tile_index: usize = @intCast(@intFromEnum(tile));

        try self.tileset.drawTile(tile_index, pos);
    }
}

pub fn getRect(self: Tilemap) Rect2 {
    const tile_width: f32 = @floatFromInt(self.tileset.tile_width);
    const tile_height: f32 = @floatFromInt(self.tileset.tile_height);
    const grid_width: f32 = @floatFromInt(self.grid_width);
    const grid_height: f32 = @floatFromInt(self.grid_height);

    return Rect2{
        .x = self.position.x,
        .y = self.position.y,
        .width = grid_width * tile_width,
        .height = grid_height * tile_height,
    };
}

pub fn center(self: *Tilemap, container_rect: Rect2) void {
    const rect = self.getRect();
    const centered_rect = Rect.centerRect(container_rect, rect);

    self.position = Rect.getRectPosition(centered_rect);
}
