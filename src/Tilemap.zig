const std = @import("std");
const raylib = @import("raylib.zig");
const Tilemap = @This();
const ArrayList = std.ArrayList;
const ArenaAllocator = std.heap.ArenaAllocator;
const Tileset = @import("Tileset.zig");

const TileTypes = enum(u16) {
    Wall,
    Ground,
};

const tile_size = 16;

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

pub fn draw(self: Tilemap, target_image: *raylib.struct_Image) !void {
    const image_w: c_int = @intCast(self.grid_width * self.tileset.tile_width);
    const image_h: c_int = @intCast(self.grid_height * self.tileset.tile_height);
    const image_rect = raylib.struct_Rectangle{ .x = 0.0, .y = 0.0, .width = @floatFromInt(image_w), .height = @floatFromInt(image_h) };
    var render_image = raylib.GenImageColor(image_w, image_h, raylib.BLACK);

    for (self.tiles.items, 0..) |tile, i| {
        const row: c_int = @intCast(i % self.grid_width);
        const col: c_int = @intCast(i / self.grid_width);
        const w: c_int = @intCast(self.tileset.tile_width);
        const h: c_int = @intCast(self.tileset.tile_height);
        const x = row * w;
        const y = col * h;
        const tile_index = @intFromEnum(tile);
        const tile_image = try self.tileset.getTileImage(tile_index);

        const tile_rect = raylib.struct_Rectangle{ .x = 0.0, .y = 0.0, .width = @floatFromInt(w), .height = @floatFromInt(h) };
        const dest_rect = raylib.struct_Rectangle{ .x = @floatFromInt(x), .y = @floatFromInt(y), .width = @floatFromInt(w), .height = @floatFromInt(h) };

        raylib.ImageDraw(&render_image, tile_image, tile_rect, dest_rect, raylib.WHITE);
    }

    raylib.ImageDraw(target_image, render_image, image_rect, image_rect, raylib.WHITE);
}
