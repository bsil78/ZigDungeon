const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const maths = @import("../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const randomizer = maths.randomizer;

const engine = @import("../engine/engine.zig");
const EntityID = engine.core.EntityID;
const NULL_ENTITY = engine.core.NULL_ENTITY;

const Inputs = engine.core.Inputs;
const Tilemap = engine.tiles.Tilemap;

const components = @import("components.zig");
const GameWorld = @import("world.zig").GameWorld;
const globals = @import("globals.zig");




pub fn moveEntity(world: *GameWorld, entity_id: EntityID, dest_cell: Vector2(i16)) void {
    if (world.getPositionMut(entity_id)) |pos| {
        pos.cell = dest_cell;
        if (world.getLocalTransformMut(entity_id)) |local| {
            local.local.position = dest_cell.times(globals.tile_size).floatFromInt(f32);
        }
        std.debug.print("Entity {d} moved to cell x: {d} y: {d}\n", .{ entity_id, dest_cell.x, dest_cell.y });
    }
}

pub fn damageEntity(world: *GameWorld, entity_id: EntityID, amount: u16) void {
    if (world.getHealthMut(entity_id)) |health| {
        health.takeDamage(amount);
        if (health.isDead()) {
            std.debug.print("Entity {d} died\n", .{entity_id});
        }
    }
}

pub fn attack(world: *GameWorld, attacker_id: EntityID, defender_id: EntityID) void {
    if (world.getActor(attacker_id)) |attacker| {
        damageEntity(world, defender_id, attacker.force);
    }
}

pub fn resolveActions(world: *GameWorld) void {
    var dead_entities: std.ArrayListUnmanaged(EntityID) = .{
        .items = &.{},
        .capacity = 0,
    };
    defer dead_entities.deinit(world.allocator);

    for (world.entities.items) |entity_id| {
        if (world.getActionPlan(entity_id)) |plan| {
            switch (plan.tag) {
                .move => {
                    moveEntity(world, entity_id, plan.target_cell);
                },
                .shoot => {
                    if (world.getEntityAtCell(plan.target_cell)) |target_id| {
                        attack(world, entity_id, target_id);
                    }
                },
            }
        }

        if (world.getHealth(entity_id)) |health| {
            if (health.isDead()) {
                dead_entities.append(world.allocator, entity_id) catch {};
            }
        }
    }

    for (dead_entities.items) |entity_id| {
        world.destroyEntity(entity_id);
    }
}

pub fn clearActionPlans(world: *GameWorld) void {
    for (world.entities.items) |entity_id| {
        _ = world.action_plans.remove(entity_id);
    }
}

pub fn planCharacterAction(world: *GameWorld, entity_id: EntityID, inputs: *const Inputs) !?components.ActionPlan {
    if (!inputs.hasAction()) {
        return null;
    }

    if (world.getPosition(entity_id)) |pos| {
        const dir: Vector2(f32) = inputs.getDirection();
        const dest_cell = pos.cell.add(&dir.intFromFloat(i16));

        if (world.getEntityAtCell(dest_cell)) |target_id| {
            if (world.getActor(entity_id)) |actor| {
                if (world.getActor(target_id)) |target_actor| {
                    if (actor.actor_type != target_actor.actor_type) {
                        return components.ActionPlan{
                            .tag = .shoot,
                            .target_cell = dest_cell,
                            .target_entity = target_id,
                        };
                    }
                }
            }
         }

        if (try world.isCellWalkable(dest_cell)) {
            return components.ActionPlan{
                .tag = .move,
                .target_cell = dest_cell,
                .target_entity = NULL_ENTITY,
            };
        }
    }

    return null;
}


pub fn planEnemyActions(world: *GameWorld, allocator: Allocator) !void {
    _ = allocator; // P2 optimization: use pre-allocated work buffer
    if (engine.frames_counter % 10 != 0) return;

    for (world.entities.items) |entity_id| {
        if (world.getActor(entity_id)) |actor| {
            if (actor.actor_type != components.ActorType.Enemy) continue;

            if (world.getPosition(entity_id)) |pos| {
                try world.populateAccessibleCells(pos.cell);
                const accessible = world.work_buffer.items;

                if (accessible.len == 0) continue;

                const random = try randomizer.random();
                const rdm_idx = random.int(usize) % accessible.len;
                const dest_cell = accessible[rdm_idx];

                const plan = components.ActionPlan{
                    .tag = .move,
                    .target_cell = dest_cell,
                    .target_entity = NULL_ENTITY,
                };

                try world.setActionPlan(entity_id, plan);
            }
        }
    }
}

pub fn handleCharacterInput(world: *GameWorld, inputs: *const Inputs, _: Allocator) !void {
    for (world.entities.items) |entity_id| {
        if (world.getActor(entity_id)) |actor| {
            if (actor.actor_type != components.ActorType.Character) continue;

            if (try planCharacterAction(world, entity_id, inputs)) |plan| {
                try world.setActionPlan(entity_id, plan);
            }
        }
    }
}

pub fn renderTilemap(tilemap: *Tilemap) !void {
    
    const gen = struct {
        pub fn tilemapRender(tilemap_ptr: *anyopaque) void {
            const tm: *Tilemap = @ptrCast(@alignCast(tilemap_ptr));
            tm.render() catch |err| {
                std.debug.print("Tilemap render error: {}\n", .{err});
            };
        }
    };
    
    try engine.core.renderer.addToRenderQueue(0, gen.tilemapRender, @ptrCast(tilemap));
}

pub fn updateTransformsSystem(world: *GameWorld) void {
    const local_transform_entities = world.local_transforms.entities();
    
    for (local_transform_entities) |entity_id| {
        if (world.getLocalTransformMut(entity_id)) |local| {
            var world_xform = local.local;
            
            if (local.parent != NULL_ENTITY) {
                if (world.getWorldTransform(local.parent)) |parent_world| {
                    world_xform = parent_world.world.xform(&local.local);
                }
            } else {
                world_xform = world.tilemap.transform.xform(&local.local);
            }
            
            if (world.getWorldTransformMut(entity_id)) |wt| {
                wt.* = .{ .world = world_xform };
            }
        }
    }
}

pub fn renderSystem(world: *GameWorld) !void {
    const renderable_entities = world.renderables.entities();
    
    for (renderable_entities) |entity_id| {
        if (world.getRenderableMut(entity_id)) |renderable| {
            if (world.getWorldTransform(entity_id)) |world_xform| {
                const sprite: *@import("../engine/sprites/Sprite.zig") = @ptrCast(@alignCast(renderable.sprite));
                sprite.transform = world_xform.world;
            }
            
            const sprite_ptr = renderable.sprite;
            const z_layer = renderable.z_layer;
            
            const gen = struct {
                pub fn spriteRender(sprite_raw: *anyopaque) void {
                    const sprite: *@import("../engine/sprites/Sprite.zig") = @ptrCast(@alignCast(sprite_raw));
                    sprite.draw();
                }
            };
            
            try engine.core.renderer.addToRenderQueue(z_layer, gen.spriteRender, sprite_ptr);
        }
    }
}

pub fn clearRenderQueue() void {
    engine.core.renderer.clearRenderQueue();
}

pub fn inputSystem(world: *GameWorld, inputs: *const Inputs) !void {
    const inputable_entities = world.inputables.entities();
    
    for (inputable_entities) |entity_id| {
        if (try planCharacterAction(world, entity_id, inputs)) |plan| {
            try world.setActionPlan(entity_id, plan);
        }
    }
}

pub fn processSystem(world: *GameWorld, allocator: Allocator) !void {
    _ = allocator;
    const processable_entities = world.processables.entities();
    
    if (engine.frames_counter % 10 != 0) return;
    
    for (processable_entities) |entity_id| {
        if (world.getActor(entity_id)) |actor| {
            if (actor.actor_type != components.ActorType.Enemy) continue;

            if (world.getPosition(entity_id)) |pos| {
                try world.populateAccessibleCells(pos.cell);
                const accessible = world.work_buffer.items;

                if (accessible.len == 0) continue;

                const random = try randomizer.random();
                const rdm_idx = random.int(usize) % accessible.len;
                const dest_cell = accessible[rdm_idx];

                const plan = components.ActionPlan{
                    .tag = .move,
                    .target_cell = dest_cell,
                    .target_entity = NULL_ENTITY,
                };

                try world.setActionPlan(entity_id, plan);
            }
        }
    }
}
