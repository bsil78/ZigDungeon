const std = @import("std");
const ActorAction = @This();
const Actor = @import("Actor.zig");
const Level = @import("Level.zig");
const Vector2 = @import("Vector.zig").Vector2;
const ActionPreview = @import("ActionPreview.zig");
const ActionType = Actor.ActionType;

level: *Level,
caster: *Actor,
action_type: ActionType,
target_cell: ?Vector2(i16),
preview: ActionPreview = null,

pub fn resolve(self: *const ActorAction) !void {
    switch (self.action_type) {
        ActionType.Move => {
            const cell = self.target_cell.?;

            if (self.level.getActorOnCell(cell)) |target| {
                try self.caster.attack(target);
            } else if (try self.level.isCellWalkable(cell)) {
                self.caster.move(cell);
            } else {
                return;
            }
        },
        ActionType.Attack => {
            if (self.level.getActorOnCell(self.target_cell.?)) |target| {
                try self.caster.attack(target);
            }
        },
    }
}
