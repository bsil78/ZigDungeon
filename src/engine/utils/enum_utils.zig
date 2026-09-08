// #region Namespace imports
const std = @import("std");
const engine = @import("../engine.zig");
// #endregion

const enumError = error{
    InvalidTag,
};

pub fn getRandomTag(T: type) !T {
    const fields = std.meta.fields(T);
    const rdm_id = try engine.random.index(fields.len);

    inline for (fields) |field| {
        if (field.value == rdm_id) {
            return @enumFromInt(field.value);
        }
    }
    return enumError.InvalidTag;
}
