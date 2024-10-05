const engine = @import("../engine/engine.zig");
const globals = @import("globals.zig");
const Vector2 = engine.maths.Vector2;
const Transform = engine.maths.Transform;
const CellTransform = @This();

cell: Vector2(i16),
transform: Transform,

pub fn init(cell: Vector2(i16), parent_transform: ?*Transform) CellTransform {
    var cell_trans = CellTransform{
        .cell = cell,
        .transform = Transform{ .parent_transform = parent_transform },
    };

    cell_trans.updatePosFromCell();
    return cell_trans;
}

pub fn initZero(parent_transform: ?*Transform) CellTransform {
    init(Vector2(i16).Zero(), parent_transform);
}

pub fn move(self: *CellTransform, to: Vector2(i16)) void {
    self.cell = to;
    self.updatePosFromCell();
}

fn updatePosFromCell(self: *CellTransform) void {
    self.transform.position = self.cell.times(globals.tile_size).floatFromInt(f32);
}
