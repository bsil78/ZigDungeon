// #region Namespace imports
const globals = @import("../globals.zig");
// #endregion

// #region Concrete imports
const GameInput = @import("../input.zig").GameInput;
const GameWorld = @import("../world.zig").GameWorld;
const Vector2 = @import("../../libs/libs.zig").maths.geometry.vectors.Vector2;
// #endregion

pub const Action = enum(u8) {
    move_right = 0b00000001,
    move_down = 0b00000010,
    move_left = 0b00000100,
    move_up = 0b00001000,
    shoot = 0b00010000,
};

pub const Inputs = struct {
    action: u8 = 0,

    pub fn fromGameInput(game_input: GameInput) Inputs {
        var inputs = Inputs{};
        if (game_input.move_up) inputs.action |= @intFromEnum(Action.move_up);
        if (game_input.move_left) inputs.action |= @intFromEnum(Action.move_left);
        if (game_input.move_down) inputs.action |= @intFromEnum(Action.move_down);
        if (game_input.move_right) inputs.action |= @intFromEnum(Action.move_right);
        if (game_input.shoot) inputs.action |= @intFromEnum(Action.shoot);
        return inputs;
    }

    pub fn isActionPressed(self: *const Inputs, action: Action) bool {
        return (self.action & @intFromEnum(action)) != 0;
    }

    pub fn getDirection(self: *const Inputs) Vector2(f32) {
        const right: i4 = @intCast(@intFromBool(self.isActionPressed(.move_right)));
        const left: i4 = @intCast(@intFromBool(self.isActionPressed(.move_left)));
        const up: i4 = @intCast(@intFromBool(self.isActionPressed(.move_up)));
        const down: i4 = @intCast(@intFromBool(self.isActionPressed(.move_down)));

        const direction = Vector2(f32).init(
            @floatFromInt(right - left),
            @floatFromInt(down - up),
        );
        if (direction.x == 0 and direction.y == 0) return direction;
        return direction.normalized();
    }
};

pub fn update(world: *GameWorld, inputs: *const Inputs) void {
    if (world.getCharacter()) |character| {
        if (!inputs.isActionPressed(.move_right) and
            !inputs.isActionPressed(.move_left) and
            !inputs.isActionPressed(.move_up) and
            !inputs.isActionPressed(.move_down)) return;

        const float_direction = inputs.getDirection();
        if (float_direction.x == 0 and float_direction.y == 0) return;
        const direction = if (float_direction.x != 0)
            Vector2(i16).init(if (float_direction.x > 0) 1 else -1, 0)
        else
            Vector2(i16).init(0, if (float_direction.y > 0) 1 else -1);
        const destination = character.cell.as(i16).add(&direction).as(globals.WORLD_SIZE_SCALAR);
        if (world.getEnemyAtCell(destination)) |entityId| {
            _ = world.damageEnemy(entityId, character.force);
            return;
        }

        if (world.isCellWalkable(destination)) |walkable| {
            if (walkable) character.move(destination);
        } else |_| {}
    }
}
