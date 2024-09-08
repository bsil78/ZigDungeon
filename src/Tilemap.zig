const std = @import("std");
const raylib = @import("raylib.zig");
const Tilemap = @This();
const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;

const TileTypes = enum {
    Wall,
    Ground,
};

const tile_size = 16;

tiles: ArrayList(TileTypes) = undefined,
grid_width: u8 = 0,
grid_height: u8 = 0,

pub fn initFromPngFile(file_path: []const u8, arena: *ArenaAllocator) !Tilemap {
    const image: raylib.struct_Image = raylib.LoadImage(file_path.ptr);
    var tilemap = Tilemap{};

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

pub fn draw(self: Tilemap) void {
    for (self.tiles.items, 0..) |tile, i| {
        const color = switch (tile) {
            TileTypes.Ground => raylib.BLACK,
            TileTypes.Wall => raylib.WHITE,
        };

        const row: c_int = @intCast(i % self.grid_width);
        const col: c_int = @intCast(i / self.grid_width);

        const x = row * tile_size;
        const y = col * tile_size;

        raylib.DrawRectangle(x, y, tile_size, tile_size, color);
    }
}

pub fn drawToTexture(self: Tilemap, image: *raylib.struct_Image) void {
    for (self.tiles.items, 0..) |tile, i| {
        const color = switch (tile) {
            TileTypes.Ground => raylib.BLACK,
            TileTypes.Wall => raylib.WHITE,
        };

        const row: c_int = @intCast(i % self.grid_width);
        const col: c_int = @intCast(i / self.grid_width);

        const x = row * tile_size;
        const y = col * tile_size;

        raylib.ImageDrawRectangle(image, x, y, tile_size, tile_size, color);
    }
}
