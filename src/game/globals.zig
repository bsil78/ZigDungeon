// #region Namespace imports
const asset_data = @import("../assets/assets.zig");
const maths = @import("../libs/maths/maths.zig");
// #endregion

// #region Concrete imports
const Vector2 = maths.geometry.vectors.Vector2;
// #endregion

pub const tile_size = Vector2(i16).initOneValue(32);

pub const assets = struct {
	pub const character_sprite = asset_data.character_sprite;
	pub const enemy_sprite = asset_data.enemy_sprite;
	pub const tileset = asset_data.tileset;
	pub const level = asset_data.level;
};

pub const messages = struct {
	pub const tilemap_render_error = "Tilemap render error: {}\n";
};
