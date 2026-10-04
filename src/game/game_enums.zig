pub const TileType = enum(u2) {
    Wall = 0,
    Ground = 1,
    Void = 2,
};

pub const LevelId = enum(u2) { LEVEL1 = 0 };

pub const Layers = enum(i16) {
    MAP = -1,
    ENEMIES = 1,
    ENEMIES_HB = 2,
    CHARACTER = 3,
    CHARACTER_HB = 4,
    GAME_OVER = 32766,
    MOUSE_POINTER = 32767,
};
