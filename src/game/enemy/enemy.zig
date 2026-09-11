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
const NPCActionPlan = @import("action_plan.zig").NPCActionPlan;
const NPCState = @import("action_plan.zig").NPCState;
// #endregion




// Represents an enemy character in the game world, 
// with properties for position, health, force, rendering, and an action plan for movement.
pub const Enemy = struct {
    entityId: usize,
    position: movement.Position,
    local_transform: movement.LocalTransform,
    world_transform: movement.WorldTransform,
    health: combat.Health,
    force: u16,
    renderable: rendering.Renderable,
    state: NPCState,
    action_plan: ?NPCActionPlan = null,

    pub fn create(allocator: Allocator, tilemap: *Tilemap,cell : Vector2(i16),state: NPCState, entityId: usize) !Enemy {  
        const local = movement.makeTransform(cell);
        const sprite = try Sprite.init(allocator, globals.assets.enemy_sprite, 1, Color.white);
        errdefer sprite.deinit();

        return .{
            .entityId=entityId,
            .position = .{ .cell = cell },
            .local_transform = .{ .local = local },
            .world_transform = .{ .world = tilemap.transform.xform(&local) },
            .health = .{ .hp = 50, .max_hp = 50 },
            .force = 5,
            .renderable = .{ .sprite = @ptrCast(sprite), .z_layer = 1, .tint = raylib.WHITE },
            .state = state,
        };
    }

    pub fn takeDamage(self: *Enemy, damage: u16) void {
        if (damage >= self.health.hp) {
            self.health.hp = 0;
        } else {
            self.health.hp -= damage;
        }
    }

    pub fn move(self: *Enemy, destination: Vector2(i16)) void {
        self.position.cell = destination;
        self.local_transform.local.position = destination.times(globals.tile_size).floatFromInt(f32);
    }

};
