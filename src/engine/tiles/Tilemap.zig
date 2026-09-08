// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const core = @import("../core/core.zig");
const raylib = core.raylib;
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Transform = maths.geometry.Transform;
const Rect = maths.geometry.shapes.Rect;
const Vector2 = maths.geometry.vectors.Vector2;
const Tileset = @import("Tileset.zig");
const Image= raylib.Image;
// #endregion


const Tilemap = @This();

pub const TilemapError = error{OutOfBound};
pub const tile_size = 32;

transform: Transform = Transform{},
tileset: Tileset,
map: ArrayList(usize) = undefined,
grid_size: Vector2(u32) = undefined,
allocator: Allocator,

pub fn initFromPngData(allocator: Allocator, image_data: []const u8, tileset: Tileset, mapper: *const fn(color:u32)usize) !*Tilemap {
    const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
    const ptr = try allocator.create(Tilemap);
    const grid_size = Vector2(u32).init(@intCast(image.width), @intCast(image.height));

    var map = try ArrayList(usize).initCapacity(allocator, @intCast(image.width * image.height));
    try initTiles(allocator, image, grid_size, &map,mapper);

    ptr.* = Tilemap{
        .tileset = tileset,
        .map = map,
        .grid_size = grid_size,
        .allocator = allocator,
    };

    return ptr;
}

fn initTiles(allocator: Allocator, image: Image, grid_size: Vector2(u32), map: *ArrayList(usize), mapper: *const fn(color: u32) usize) !void {
    for (0..grid_size.y) |row| {
        for (0..grid_size.x) |column| {
            const cell = Vector2(i16).init(@intCast(column), @intCast(row));
            const color = image.GetImageColor(cell.x, cell.y);
            const color_value: u8 = @intCast(color.r);
            const tile_type: usize = mapper(color_value);
            try map.append(allocator, tile_type);
        }
    }
}
    
pub fn getTile(self: *Tilemap, cell: Vector2(i16)) Tilemap.TilemapError!usize {
    const width: i16 = @intCast(self.grid_size.x);
    const id: i16 = cell.y * width + cell.x;
    if (id >= self.map.items.len) {
        return Tilemap.TilemapError.OutOfBound;
    }
    return self.map.items[@intCast(id)];
}

pub fn deinit(self: *Tilemap) void {
    self.map.deinit(self.allocator);
    self.allocator.destroy(self);
}

pub fn print(self: *Tilemap) void {
    for (self.map.items, 0..) |tile, i| {
        if (i % self.grid_size.x == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{s:^10}", .{@tagName(tile)});
    }

    std.debug.print("\n", .{});
}

pub fn render(self: *Tilemap) !void {
    for (self.map.items, 0..) |tile, i| {
        const cell = Vector2(f32).init(@floatFromInt(i % self.grid_size.x), @floatFromInt(i / self.grid_size.x));
        const size = Vector2(u32).init(self.tileset.tile_width, self.tileset.tile_height).floatFromInt(f32);
        const pos = self.transform.position.add(cell.times(size));
        try self.tileset.drawTile(tile, pos);
    }
}

pub fn getRect(self: *Tilemap) Rect(f32) {
    const tile_width: f32 = @floatFromInt(self.tileset.tile_width);
    const tile_height: f32 = @floatFromInt(self.tileset.tile_height);
    const grid_width: f32 = @floatFromInt(self.grid_size.x);
    const grid_height: f32 = @floatFromInt(self.grid_size.y);

    return Rect(f32).init(
        self.transform.position.x,
        self.transform.position.y,
        grid_width * tile_width,
        grid_height * tile_height,
    );
}

pub fn center(self: *Tilemap, container_rect: Rect(f32)) void {
    const rect = self.getRect();
    const centered_rect = rect.centerRect(container_rect);

    self.transform.position = centered_rect.getRectPosition();
}



pub fn tileExist(self: *Tilemap, cell: Vector2(i16)) bool {
const width: i16 = @intCast(self.grid_size.x);
    const id:i16 = cell.y * width + cell.x;
    return id < self.map.items.len;
}
