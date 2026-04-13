const std = @import("std");

const maths = @import("../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const Transform = maths.geometry.Transform;

const raylib = @import("../engine/vendors/raylib.zig").raylib;
const core = @import("../engine/core/core.zig");
const EntityID = core.EntityID;
const NULL_ENTITY = core.NULL_ENTITY;


pub const ActorType = enum {
    Character,
    Enemy,
};

pub const Position = struct {
    cell: Vector2(i16),
};

pub const LocalTransform = struct {
    parent: EntityID = NULL_ENTITY,  // NULL_ENTITY = root (no parent)
    local: Transform,                 // Transform relative to parent
};

pub const WorldTransform = struct {
    world: Transform,  // Absolute world transform (computed from hierarchy)
};

pub const Health = struct {
    hp: u16,
    max_hp: u16,

    pub fn isDead(self: Health) bool {
        return self.hp == 0;
    }

    pub fn takeDamage(self: *Health, amount: u16) void {
        if (self.hp > amount) {
            self.hp -= amount;
        } else {
            self.hp = 0;
        }
    }

    pub fn heal(self: *Health, amount: u16) void {
        if (self.hp + amount > self.max_hp) {
            self.hp = self.max_hp;
        } else {
            self.hp += amount;
        }
    }
};

pub const Actor = struct {
    actor_type: ActorType,
    force: u16 = 1,
};

pub const Renderable = struct {
    sprite: *anyopaque,  // *Sprite, stored as opaque to avoid circular imports
    z_layer: i16 = 0,
    tint: raylib.Color = raylib.WHITE,
};

pub const SpriteData = struct {
    sprite: *anyopaque,  // *Sprite, opaque pointer
};

pub const Inputable = struct {
};

pub const Processable = struct {
};

pub const ActionPlan = struct {
    pub const Tag = enum {
        move,
        shoot,
    };

    tag: Tag,
    target_cell: Vector2(i16),
    target_entity: EntityID = NULL_ENTITY,
};

pub const Tile = struct {
    is_walkable: bool,
};

pub const Entity = struct {
    id: EntityID,
    alive: bool = true,
};


