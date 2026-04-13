const std = @import("std");
const Allocator = std.mem.Allocator;

const maths = @import("../libs/maths/maths.zig");
const Vector2 = maths.geometry.vectors.Vector2;
const Transform = maths.geometry.Transform;
const Color = @import("../libs/gfx/gfx.zig").Color;

const engine = @import("../engine/engine.zig");
const Sprite = engine.sprites.Sprite;
const raylib = engine.core.raylib;
const EntityID = engine.core.EntityID;
const NULL_ENTITY = engine.core.NULL_ENTITY;

const components = @import("components.zig");
const GameWorld = @import("world.zig").GameWorld;
const globals = @import("globals.zig");

pub fn createCharacter(
    world: *GameWorld,
    allocator: Allocator,
    texture_path: []const u8,
    cell: Vector2(i16),
) !EntityID {
    const entity_id = try world.createEntity();

    const pos_int = cell.times(globals.tile_size);
    const local_transform = Transform{
        .position = Vector2(f32).init(
            @floatFromInt(pos_int.x),
            @floatFromInt(pos_int.y),
        ),
    };
    
    try world.setPosition(entity_id, components.Position{
        .cell = cell,
    });

    try world.setLocalTransform(entity_id, components.LocalTransform{
        .parent = NULL_ENTITY,
        .local = local_transform,
    });

    const world_transform = world.tilemap.transform.xform(&local_transform);
    try world.setWorldTransform(entity_id, components.WorldTransform{
        .world = world_transform,
    });

    try world.setHealth(entity_id, components.Health{
        .hp = 100,
        .max_hp = 100,
    });

    try world.setActor(entity_id, components.Actor{
        .actor_type = components.ActorType.Character,
        .force = 10,
    });

    const sprite = try @import("../engine/sprites/Sprite.zig").init(allocator, texture_path, 1, Color.white);
    try world.setSprite(entity_id, components.SpriteData{ .sprite = @ptrCast(sprite) });

    try world.setRenderable(entity_id, components.Renderable{
        .sprite = @ptrCast(sprite),
        .z_layer = 1,
        .tint = raylib.WHITE,
    });
    try world.addInputable(entity_id);
    try world.addProcessable(entity_id);

    return entity_id;
}

pub fn createEnemy(
    world: *GameWorld,
    allocator: Allocator,
    texture_path: []const u8,
    cell: Vector2(i16),
) !EntityID {
    const entity_id = try world.createEntity();

    const pos_int = cell.times(globals.tile_size);
    const local_transform = Transform{
        .position = Vector2(f32).init(
            @floatFromInt(pos_int.x),
            @floatFromInt(pos_int.y),
        ),
    };
    
    try world.setPosition(entity_id, components.Position{
        .cell = cell,
    });

    try world.setLocalTransform(entity_id, components.LocalTransform{
        .parent = NULL_ENTITY,
        .local = local_transform,
    });

    const world_transform = world.tilemap.transform.xform(&local_transform);
    try world.setWorldTransform(entity_id, components.WorldTransform{
        .world = world_transform,
    });

    try world.setHealth(entity_id, components.Health{
        .hp = 50,
        .max_hp = 50,
    });

    try world.setActor(entity_id, components.Actor{
        .actor_type = components.ActorType.Enemy,
        .force = 5,
    });

    const sprite = try @import("../engine/sprites/Sprite.zig").init(allocator, texture_path, 1, Color.white);
    try world.setSprite(entity_id, components.SpriteData{ .sprite = @ptrCast(sprite) });

    try world.setRenderable(entity_id, components.Renderable{
        .sprite = @ptrCast(sprite),
        .z_layer = 1,
        .tint = raylib.WHITE,
    });
    try world.addProcessable(entity_id);

    return entity_id;
}
