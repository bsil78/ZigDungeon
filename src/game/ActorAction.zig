const std = @import("std");
const engine = @import("../engine/engine.zig");
const Actor = @import("Actor.zig");
const Level = @import("Level.zig");
const ActionPreview = @import("ActionPreview.zig");
const CellTransform = @import("CellTransform.zig");

const ActorAction = @This();

const Allocator = std.mem.Allocator;
const ActionType = Actor.ActionType;
const Vector2 = engine.maths.Vector.Vector2;

allocator: Allocator,
level: *Level,
caster: *Actor,
action_type: ActionType,
cell_transform: CellTransform,
preview: ?*ActionPreview = null,

pub fn init(allocator: Allocator, level: *Level, caster: *Actor, action_type: ActionType, cell: Vector2(i16)) !*ActorAction {
    const ptr = try allocator.create(ActorAction);

    ptr.* = .{
        .level = level,
        .caster = caster,
        .action_type = action_type,
        .cell_transform = CellTransform.init(cell, null),
        .allocator = allocator,
    };

    ptr.*.preview = try ActionPreview.init(allocator, cell, ptr);

    return ptr;
}

pub fn deinit(self: *const ActorAction) !void {
    if (self.preview) |prw| {
        try prw.deinit();
    }
    self.allocator.destroy(self);
}

pub fn resolve(self: *const ActorAction) !void {
    switch (self.action_type) {
        ActionType.Move => {
            const cell = self.cell_transform.cell;

            if (self.level.getActorOnCell(cell)) |target| {
                try self.caster.attack(target);
            } else if (try self.level.isCellWalkable(cell)) {
                self.caster.move(cell);
            } else {
                return;
            }
        },
        ActionType.Attack => {
            if (self.level.getActorOnCell(self.cell_transform.cell)) |target| {
                try self.caster.attack(target);
            }
        },
    }
}
