// #region Namespace imports
pub const libs = @import("../../libs/libs.zig");
const globals = @import("../globals.zig");
// #endregion

// #region Concrete imports
const Transform = @import("../../engine/core/core.zig").rendering.Transform;
const Vector2 = libs.maths.geometry.vectors.Vector2;
const WorldCell = @import("../game_types.zig").WorldCell;
// #endregion

pub fn transformFromCell(cell: WorldCell) Transform {
    const position = cell.as(u16).times(globals.TILES_SIZE);
    return Transform{ .position = Vector2(f32).init(@floatFromInt(position.x), @floatFromInt(position.y)) };
}

pub fn transformForSprite(
    cell: WorldCell,
    sprite_width: u16,
    sprite_height: u16,
    parent_transform: Transform,
) Transform {
    var transform = transformFromCell(cell).xform(parent_transform);
    const tile_width: f32 = @floatFromInt(globals.TILES_SIZE.x);
    const tile_height: f32 = @floatFromInt(globals.TILES_SIZE.y);
    const scaled_sprite_width = @as(f32, @floatFromInt(sprite_width)) * transform.scale.x;
    const scaled_sprite_height = @as(f32, @floatFromInt(sprite_height)) * transform.scale.y;

    transform.position.x += (tile_width - scaled_sprite_width) / 2.0;
    transform.position.y += (tile_height - scaled_sprite_height) / 2.0;
    return transform;
}
