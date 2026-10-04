// #region Namespace imports
const engine = @import("../engine/engine.zig");
const globals = @import("globals.zig");
const systems = @import("systems/systems.zig");
// #endregion

// #region Concrete imports
const Character = @import("character/character.zig").Character;
const Soldier = @import("npc/soldier/soldier.zig").Soldier;
const Slime = @import("npc/slime/slime.zig").Slime;
const WorldCell = @import("game_types.zig").WorldCell;
const SizedRenderable = @import("game_types.zig").SizedRenderable;
const Health = @import("components/health.zig").Health;
const Visual = @import("components/visual.zig").Visual;
const NPCEntityData = @import("npc/generic/npc_entity_data.zig").NPCEntityData;
const Transform = @import("../engine/core/subsystems/rendering.zig").Transform;
// #endregion

pub const EntityType = enum {
    character,
    soldier,
    slime,
};

pub const EntityData = union(EntityType) {
    character: Character,
    soldier: Soldier,
    slime: Slime,
};

pub const Entity = struct {
    id: globals.EntityId,
    data: EntityData,
    // Texture handles in the visual payloads are borrowed; GameWorld.assets owns the GPU resources.
    cell: WorldCell,
    health: Health,
    force: u16,
    parent_transform: Transform,
    normal_speed: f32 = 1.0,
    max_speed: f32 = 3.0,
    movement_elapsed: f32 = 0.0,

    pub fn entityType(self: *const Entity) EntityType {
        return self.data;
    }

    pub fn npcData(self: *Entity) ?*NPCEntityData {
        return switch (self.data) {
            .character => null,
            .soldier => |*soldier| &soldier.npc,
            .slime => |*slime| &slime.npc,
        };
    }

    pub fn move(self: *Entity, destination: WorldCell) void {
        self.cell = destination;
    }

    pub fn visualTransform(self: *const Entity) Transform {
        return self.transformForVisual(self.visual());
    }

    fn transformForVisual(self: *const Entity, visual_data: Visual) Transform {
        return systems.transformForSprite(
            self.cell,
            @intCast(visual_data.width()),
            @intCast(visual_data.height()),
            self.parent_transform,
        );
    }

    pub fn visual(self: *const Entity) Visual {
        return switch (self.data) {
            .character => |*value| value.visual(),
            .soldier => |*value| value.visual(),
            .slime => |*value| value.visual(),
        };
    }

    pub fn renderable(self: *const Entity) SizedRenderable {
        const visual_data = self.visual();
        const transform = self.transformForVisual(visual_data);
        return .{
            .id = self.id,
            .renderingFn = SizedRenderable.drawTexture,
            .renderingCtx = if (visual_data.source) |source|
                SizedRenderable.textureRegionContext(visual_data.texture, source, transform)
            else
                SizedRenderable.textureContext(visual_data.texture, transform),
            .z_layer = visual_data.z_layer,
        };
    }
};
