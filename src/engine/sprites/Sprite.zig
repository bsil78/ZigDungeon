const std = @import("std");
const raylib = @import("../core/raylib.zig");
const maths = @import("../maths/maths.zig");
const traits = @import("../traits/traits.zig");
const Vector2 = maths.Vector.Vector2;
const Rect = maths.Rect;
const Transform = maths.Transform;
const Allocator = std.mem.Allocator;
const Sprite = @This();

render_trait: *traits.RenderTrait,
allocator: Allocator,
texture: raylib.Texture2D,
transform: Transform = Transform{},
size: Vector2(f32),
pivot: Vector2(f32) = Vector2(f32).Zero(),

pub fn init(allocator: Allocator, texture_path: []const u8, parent_transform: ?*Transform, z_layer: i16) !*Sprite {
    const texture = raylib.LoadTexture(texture_path.ptr);
    const ptr = try allocator.create(Sprite);
    const render_trait = try traits.RenderTrait.init(allocator, ptr);
    render_trait.z_layer = z_layer;

    ptr.* = Sprite{
        .texture = texture,
        .size = Vector2(f32).init(@floatFromInt(texture.width), @floatFromInt(texture.height)),
        .render_trait = render_trait,
        .allocator = allocator,
        .transform = Transform{
            .parent_transform = parent_transform,
        },
    };

    return ptr;
}

pub fn deinit(self: *Sprite) !void {
    try self.render_trait.deinit();
    self.allocator.destroy(self);
}

pub fn render(self: *Sprite) void {
    const trans = self.transform.toGlobal();

    raylib.DrawTexturePro(
        self.texture,
        Rect(f32).initV(Vector2(f32).Zero(), self.size).toRaylib(),
        Rect(f32).initV(trans.position, self.size.times(trans.scale)).toRaylib(),
        self.pivot.toRaylib(),
        trans.rotation,
        raylib.WHITE,
    );
}
