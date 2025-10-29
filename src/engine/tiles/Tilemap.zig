const std = @import("std");
const core = @import("../core/core.zig");
const maths = @import("../maths/maths.zig");
const traits = @import("../traits/traits.zig");
const Tileset = @import("Tileset.zig");
const Tilemap = @This();

const raylib = core.raylib;
const Allocator = std.mem.Allocator;
const Transform = maths.Transform;
const Rect = maths.Rect;
const ArrayList = std.ArrayList;
const Vector2 = maths.Vector.Vector2;

const TileType = enum(u16) {
    Wall,
    Ground,
    Void,
};

pub const TilemapError = error{OutOfBound};
pub const tile_size = 32;

render_trait: *traits.RenderTrait = undefined,
transform: Transform = Transform{},
tileset: Tileset,
tiles: ArrayList(TileType) = undefined,
grid_size: Vector2(u32) = undefined,
allocator: Allocator,

pub fn initFromPngFile(allocator: Allocator, file_path: []const u8, tileset: Tileset) !*Tilemap {
    const image = raylib.LoadImage(file_path.ptr);
    const ptr = try allocator.create(Tilemap);

    ptr.* = Tilemap{
        .tileset = tileset,
        .tiles = try ArrayList(TileType).initCapacity(allocator,256),
        .grid_size = Vector2(u32).init(@intCast(image.height), @intCast(image.width)),
        .render_trait = try traits.RenderTrait.autoInit(allocator, ptr, 0),
        .allocator = allocator,
    };

    for (0..ptr.grid_size.y) |column| {
        for (0..ptr.grid_size.x) |row| {
            const color: raylib.struct_Color = raylib.GetImageColor(image, @intCast(row), @intCast(column));
            const tile = if (color.r == 0.0) TileType.Ground else TileType.Wall;
            ptr.*.tiles.appendAssumeCapacity(tile);
        }
    }

    return ptr;
}

pub fn deinit(self: *Tilemap) !void {
    try self.render_trait.deinit();
    self.allocator.destroy(self);
}

/// Print all the TileType of the tilemap in a grid like fashion
pub fn print(self: *Tilemap) void {
    for (self.tiles.items, 0..) |tile, i| {
        if (i % self.grid_size.x == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{s:^10}", .{@tagName(tile)});
    }

    std.debug.print("\n", .{});
}

/// Draw all the tiles of the tilemap
pub fn render(self: *Tilemap) !void {
    for (self.tiles.items, 0..) |tile, i| {
        const cell = Vector2(f32).init(@floatFromInt(i % self.grid_size.x), @floatFromInt(i / self.grid_size.x));
        const size = Vector2(u32).init(self.tileset.tile_width, self.tileset.tile_height).floatFromInt(f32);
        const pos = self.transform.position.add(cell.times(size));
        const tile_index: usize = @intCast(@intFromEnum(tile));

        try self.tileset.drawTile(tile_index, pos);
    }
}

/// Get the rect in pixels encapsulating of all the tiles in the tilemap
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

/// Move this Tilemap so it is centered inside the given container rect
pub fn center(self: *Tilemap, container_rect: Rect(f32)) void {
    const rect = self.getRect();
    const centered_rect = rect.centerRect(container_rect);

    self.transform.position = centered_rect.getRectPosition();
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
    const width: i16 = @intCast(self.grid_size.x);
    const id = cell.y * width + cell.x;

    if (id >= self.tiles.items.len) {
        return TilemapError.OutOfBound;
    }

    return @intCast(id);
}

pub fn tileExist(self: Tilemap, cell: Vector2(i16)) bool {
    const width: i16 = @intCast(self.grid_size.x);
    const id = cell.y * width + cell.x;
    return id >= self.tiles.items.len;
}
