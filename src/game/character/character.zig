// #region Namespace imports
const std = @import("std");
const maths = @import("../../libs/maths/maths.zig");
const gfx = @import("../../libs/gfx/gfx.zig");
const engine = @import("../../engine/engine.zig");
const raylib = engine.core.raylib;
const globals = @import("../globals.zig");
const combat = @import("../combat/components.zig");
const movement = @import("../movement/components.zig");
const rendering = @import("../rendering/components.zig");
// #endregion

// #region Concrete imports
const Allocator = std.mem.Allocator;
const Vector2 = maths.geometry.vectors.Vector2;
const Transform = maths.geometry.Transform;
const Color = gfx.Color;
const Sprite = engine.sprites.Sprite;
const Tilemap = engine.tiles.Tilemap;
// #endregion


// Represents the player character in the game world,
// with properties for position, health, force, and rendering.
pub const Character = struct {
    position: movement.Position,
    local_transform: movement.LocalTransform,
    world_transform: movement.WorldTransform,
    health: combat.Health,
    force: u16,
    renderable: rendering.Renderable,

    // Creates a new Character instance with the specified allocator and tilemap.
    // Initializes the character's position, transforms, health, force, and rendering properties.
    pub fn create(allocator: Allocator, tilemap: *Tilemap, position: Vector2(i16)) !Character {
        const cell = position;
        const local = movement.makeTransform(cell);
        const sprite = try Sprite.init(allocator, globals.assets.character_sprite, 1, Color.white);
        errdefer sprite.deinit();

        return .{
            .position = .{ .cell = cell },
            .local_transform = .{ .local = local },
            .world_transform = .{ .world = tilemap.transform.xform(&local) },
            .health = .{ .hp = 100, .max_hp = 100 },
            .force = 10,
            .renderable = .{ .sprite = @ptrCast(sprite), .z_layer = 1, .tint = raylib.WHITE },
        };
    }

    pub fn move(self: *Character, destination: Vector2(i16)) void {
        self.position.cell = destination;
        self.local_transform.local.position = destination.times(globals.tile_size).floatFromInt(f32);
    }
};
