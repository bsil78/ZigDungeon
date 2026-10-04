pub const TypesHelper = struct {
    /// Liste des assertions disponibles
    pub const Asserts = enum {
        unsigned_int,
        signed_int,
        float,
        numeric,
        slice,
        struct_type,
    };

    /// Valide qu'un type `T` respecte l'assertion demandée.
    /// Émet une @compileError si l'assertion échoue.
    pub fn assert(comptime T: type, comptime assertion: Asserts, comptime type_def: [:0]const u8) void {
        comptime {
            const ok = isType(T, assertion);
            if (!ok) {
                @compileError("Type assertion failed : " ++ @typeName(T) ++
                    " (" ++ type_def ++ ") does not satisfy assertion '." ++ @tagName(assertion) ++ "'");
            }
        }
    }

    fn isType(comptime T: type, comptime assertion: Asserts) bool {
        const T_Infos=@typeInfo(T);

        return switch (assertion) {
            .unsigned_int => switch (T_Infos){
                .int => |info| info.signedness == .unsigned,
                else => false,
            },
            .signed_int => switch (T_Infos) {
                .int => |info| info.signedness == .signed,
                else => false,
            },
            .float => T_Infos == .float,
            .numeric => isType(T, Asserts.unsigned_int) or isType(T, Asserts.signed_int) or isType(T, Asserts.float),
            .slice => T_Infos == .pointer and @typeInfo(T).pointer.size == .slice,
            .struct_type => T_Infos == .@"struct",
        };
    }

    /// Renvoie le tag d'enum ayant la valeur entière maximale.
    pub fn maxEnum(comptime T: type) T {
        comptime {
            const info = @typeInfo(T);
            if (info != .Enum) {
                @compileError("maxEnum exige un type Enum, reçu : " ++ @typeName(T));
            }

            const fields = info.Enum.fields;
            if (fields.len == 0) {
                @compileError("L'enum " ++ @typeName(T) ++ " est vide !");
            }

            var max_val = fields[0].value;
            var max_tag = fields[0];

            for (fields[1..]) |field| {
                if (field.value > max_val) {
                    max_val = field.value;
                    max_tag = field;
                }
            }

            // Convertit la valeur entière en tag d'enum
            return @enumFromInt(max_val);
        }
    }
};
