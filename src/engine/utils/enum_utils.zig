const std = @import("std");
const engine = @import("../engine.zig");
const randomizer = engine.maths.randomizer;

const enumError = error{
    InvalidTag,
};

pub fn getRandomTag(T: type) !T {
    const fields = std.meta.fields(T);
    const random = try randomizer.random();
    const rdm_id = random.int(usize) % fields.len;

    inline for (fields) |field| {
        if (field.value == rdm_id) {
            return @enumFromInt(field.value);
        }
    }
    return enumError.InvalidTag;
}
