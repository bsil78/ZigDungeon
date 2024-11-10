const std = @import("std");
const engine = @import("../engine/engine.zig");
const actions = @import("actions.zig");
const traits = engine.traits;
const randomizer = engine.maths.randomizer;
const enum_utils = engine.utils.enum_utils;
const Level = @import("Level.zig");
const Actor = @import("Actor.zig");
const ActionPreview = actions.ActionPreview;
const ArrayList = std.ArrayList;
const Inputs = engine.core.Inputs;
const Vector2 = engine.maths.Vector2;
const Combat = @This();
const Allocator = std.mem.Allocator;

allocator: Allocator,
level: *Level,
action_previews: ArrayList(*ActionPreview),
input_trait: traits.InputTrait,

pub fn init(allocator: Allocator, level: *Level) !*Combat {
    const ptr = try allocator.create(Combat);

    ptr.* = .{
        .level = level,
        .allocator = allocator,
        .input_trait = try traits.InputTrait.init(ptr),
        .action_previews = ArrayList(*ActionPreview).init(allocator),
    };

    return ptr;
}

pub fn deinit(self: *Combat) void {
    self.allocator.destroy(self);
}

pub fn input(self: *Combat, inputs: *const Inputs) !void {
    if (!inputs.hasAction()) {
        return;
    }

    for (self.level.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Enemy) {
            continue;
        }

        var dir: Vector2(f32) = inputs.getDirection();
        const dest_cell = actor.cell_transform.cell.add(&dir.intFromFloat(i16));

        if (self.level.getActorOnCell(dest_cell)) |target| {
            try actor.attack(target);
        } else if (try self.level.isCellWalkable(dest_cell)) {
            actor.move(dest_cell);
        } else {
            return;
        }
    }
    try self.enemiesResolveActions();
    try self.enemiesPlanActions();
    try self.updatePreviews(self.allocator);
}

fn updatePreviews(self: *Combat, allocator: Allocator) !void {
    if (self.action_previews.items.len > 0) {
        for (self.action_previews.items) |preview| {
            try preview.deinit();
        }
        try self.action_previews.resize(0);
    }

    for (self.level.actors.items) |actor| {
        if (actor.next_action) |action| {
            try self.action_previews.append(try action.preview(allocator));
        }
    }
}

fn enemiesPlanActions(self: *Combat) !void {
    for (self.level.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Character) {
            continue;
        }

        var cells = try self.level.getAccessibleCells(self.allocator, actor.cell_transform.cell);
        defer cells.deinit();

        if (cells.items.len == 0) {
            actor.next_action = null;
            continue;
        }

        const random = try randomizer.random();
        const rdm_id = random.int(usize) % cells.items.len;

        const dest_cell = cells.items[rdm_id];
        const TagActorAction = actions.TagActorAction;
        const tag = try enum_utils.getRandomTag(TagActorAction);

        actor.next_action = switch (tag) {
            TagActorAction.move => actions.ActorAction{
                .move = try actions.MoveAction.init(self.allocator, actor, self.level, dest_cell),
            },
            TagActorAction.shoot => actions.ActorAction{
                .shoot = try actions.ShootAction.init(self.allocator, actor, self.level, Vector2(i16).Right()),
            },
        };
    }
}

fn enemiesResolveActions(self: *Combat) !void {
    for (self.level.actors.items) |actor| {
        if (actor.actor_type == Actor.ActorType.Character) {
            continue;
        }

        if (actor.next_action) |action| {
            try action.resolve();
            actor.next_action = null;
        }
    }
}
