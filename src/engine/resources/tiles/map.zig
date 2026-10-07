// #region Namespace imports
const std = @import("std");
const libs = @import("../../../libs/libs.zig");
const geometry = libs.maths.geometry;
const raylib = @import("../../vendors/vendors.zig").raylib;
const rendering = @import("../../core/core.zig").rendering;
// #endregion

// #region Concrete imports
const Renderable = rendering.Renderable;
const Transform = rendering.Transform;
const Rect = geometry.shapes.Rect;
const Vector2 = geometry.vectors.Vector2;
const TilesSet = @import("set.zig").TilesSet;
const Image = raylib.Image;
const TypesHelper = libs.utils.TypesHelper;
// #endregion

/// **Contraintes de type :**
/// - `T` doit être un type unsigned integer
///     et désigne le type qui permet de stocker le nombre de tiles possibles (typiquement @TypeOf(tiles_types_count))
/// - `S` doit être une instance de `Vector2(D)` avec `D` doit être un type numérique (entier ou flottant)
///    et désigne la taille width/height de la map
pub fn TilesMap(comptime T: type, comptime S: anytype) type {
    TypesHelper.assert(T, TypesHelper.Asserts.unsigned_int, "tiles count type");

    const SizeScalar = @TypeOf(S).SCALAR;
    const SizeVector = Vector2(SizeScalar);

    comptime {
        const is_vector2 = @hasDecl(SizeVector, "SCALAR") and SizeVector == Vector2(SizeScalar);
        TypesHelper.assert(SizeScalar, TypesHelper.Asserts.unsigned_int, "size dimensions type");
        if (!is_vector2) {
            @compileError("L'argument 'S' doit etre un 'Vector2(numeric_type)', recu : " ++ @typeName(SizeVector));
        }
    }

    return struct {
        pub const TILE_TYPE: type = T;
        pub const SIZE: SizeVector = S;
        pub const MAP_LENGTH: u16 = @as(u16, SIZE.x) * @as(u16, SIZE.y);

        transform: Transform = .{},
        map: [MAP_LENGTH]T = undefined,

        pub const Error = error{ OutOfBound, NotMatchingImageSize };

        pub fn initFromPngData(image_data: []const u8, mapper: *const fn (color: u32) T) Error!TilesMap(T, S) {
            const image = raylib.LoadImageFromMemory(".png", image_data.ptr, @intCast(image_data.len));
            defer raylib.UnloadImage(image);
            const imgW: SizeScalar = @intCast(image.width);
            const imgH: SizeScalar = @intCast(image.height);
            if (imgW != SIZE.x or imgH != SIZE.y) {
                return Error.NotMatchingImageSize;
            }
            return .{
                .map = initTiles(image, SIZE, mapper),
            };
        }

        fn initTiles(image: Image, grid_size: SizeVector, mapper: *const fn (color: u32) T) [MAP_LENGTH]T {
            var map: [MAP_LENGTH]T = undefined;

            for (0..grid_size.y) |row| {
                for (0..grid_size.x) |column| {
                    const cell = SizeVector.init(@intCast(column), @intCast(row));
                    const color = image.GetImageColor(cell.x, cell.y);
                    const color_value: u8 = @intCast(color.r);
                    const tile_type: T = mapper(color_value);
                    const id = grid_size.y * row + column;
                    map[id] = tile_type;
                }
            }
            return map;
        }

        pub fn getTile(self: TilesMap(T, S), cell: SizeVector) Error!T {
            if (!self.tileExist(cell)) {
                return Error.OutOfBound;
            }
            const width: i16 = @intCast(S.x);
            const id: i16 = cell.y * width + cell.x;
            return self.map[@intCast(id)];
        }

        pub fn print(self: TilesMap(T, S)) void {
            for (self.map, 0..) |tile, i| {
                if (i % SIZE.x == 0) {
                    std.log.info("\n", .{});
                }
                std.log.info("{x} ", .{tile});
            }
            std.log.info("\n", .{});
        }

        pub fn renderable(self: TilesMap(T, S), comptime tilesSetType: type, tilesSet: *anyopaque, comptime MAX_CONTEXT_SIZE: usize, z_layer: i16) Renderable(MAX_CONTEXT_SIZE) {
            comptime {
                const expectedType = TilesSet(tilesSetType.COUNT, tilesSetType.TILE_SIZE);
                if (tilesSetType != expectedType) {
                    @compileError("L'argument doit être un TilesSet valide.");
                }
            }
            const COUNT: tilesSetType.TC = tilesSetType.COUNT;
            const TILE_SIZE = tilesSetType.TILE_SIZE;
            const tilesSetInstance: *const TilesSet(COUNT, TILE_SIZE) = @ptrCast(@alignCast(tilesSet));

            const CONTEXT = struct {
                tilesMap: TilesMap(T, S),
                tilesSet: *const TilesSet(COUNT, TILE_SIZE),
            };

            const contextToUse = CONTEXT{ .tilesMap = self, .tilesSet = tilesSetInstance };
            const preparedContext = Renderable(MAX_CONTEXT_SIZE).contextCopy(CONTEXT, &contextToUse);
            return Renderable(MAX_CONTEXT_SIZE){
                .renderingFn = struct {
                    fn draw(ctx: *anyopaque) void {
                        //std.log.info("Rendering tilemap", .{});
                        const context: CONTEXT = Renderable(MAX_CONTEXT_SIZE).restoreContext(CONTEXT, ctx);
                        for (context.tilesMap.map, 0..) |tileId, i| {
                            const cell = SizeVector.init(@intCast(i % S.x), @intCast(i / S.x));
                            if (!context.tilesMap.tileExist(cell)) {
                                std.debug.panic("Out of bound cell {any} !", .{cell});
                            }
                            const tile = context.tilesSet.tiles[@intCast(tileId)];
                            const pos = context.tilesMap.transform.position.add(cell.as(f32).times(TILE_SIZE.as(f32)));
                            tile.draw(pos);
                        }
                    }
                }.draw,
                .renderingCtx = preparedContext,
                .z_layer = z_layer,
            };
        }

        pub fn center(self: *TilesMap(T, S), container_rect: Rect(f32), tileSize: Vector2(u16)) void {
            const rect = Rect(f32).init(0.0, 0.0, @TypeOf(self.*).SIZE.x * tileSize.x, @TypeOf(self.*).SIZE.y * tileSize.y);
            const centered_rect = rect.centerRect(container_rect);
            self.transform.position = centered_rect.getRectPosition();
        }

        pub fn tileExist(_: TilesMap(T, S), cell: SizeVector) bool {
            if (cell.x >= S.x) return false;
            if (cell.y >= S.y) return false;
            if (cell.x < 0) return false;
            if (cell.y < 0) return false;
            return true;
        }
    };
}
