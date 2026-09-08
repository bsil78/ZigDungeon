# Zig cheat sheet

This note gathers the Zig idioms that matter most for this project and the errors that show up most often when working with structs, collections, and optionals.

## 1) `const` vs `var`

Use `const` for immutable bindings and `var` for values that will change.

```zig
const x = 42;
var y = 42;
y = 43;
```

Common rule:

- use `const` when you do not plan to mutate
- use `var` when you build or update a value

## 2) `?T` and `null`

In Zig, a value that may be absent is an optional type.

```zig
var maybe_value: ?u32 = null;
maybe_value = 10;
```

Accessing an optional requires unwrapping:

```zig
std.debug.assert(maybe_value != null);
const value = maybe_value.?;
```

This is the Zig equivalent of checking whether something was initialized.

## 3) `undefined` is not a normal value for a struct

This is a common beginner mistake:

```zig
var settings: Settings = undefined;
```

This is valid only for some cases and is not a good pattern for normal struct initialization.

Prefer:

```zig
var settings: ?Settings = null;
```

Then check:

```zig
std.debug.assert(settings != null);
const current = settings.?;
```

Do not compare a struct to `undefined`.

## 4) Mutation requires a pointer

If a function needs to mutate a container or struct, it usually takes a pointer to it.

```zig
fn appendValue(list: *std.ArrayList(u32), value: u32) !void {
    try list.append(value);
}
```

This is different from passing a copied value.

This is why this pattern fails:

```zig
const map = try std.ArrayList(usize).initCapacity(allocator, 100);
_ = map.append(allocator, 42);
```

because `map` is immutable, and `append` mutates the list.

The correct pattern is:

```zig
var map = try std.ArrayList(usize).initCapacity(allocator, 100);
try map.append(allocator, 42);
```

or pass a pointer:

```zig
fn initTiles(map: *std.ArrayList(usize)) !void {
    try map.append(allocator, 42);
}
```

## 5) `try` is required for fallible operations

Many Zig operations return error unions.

```zig
try map.append(allocator, item);
```

This is different from silently discarding the result:

```zig
_ = map.append(allocator, item);
```

The second version hides errors and is usually wrong.

## 6) `errdefer` is useful for cleanup

When a constructor allocates resources and may fail later, `errdefer` ensures cleanup happens on failure.

```zig
const sprite = try Sprite.init(allocator, ...);
errdefer sprite.deinit();
```

This keeps resource ownership clear.

## 7) Methods belong to the type that owns the data

If a method mutates fields of a struct, prefer a method on that struct.

Good:

```zig
pub const Enemy = struct {
    position: Position,

    pub fn move(self: *Enemy, destination: Vector2(i16)) void {
        self.position.cell = destination;
    }
};
```

Then call it as:

```zig
enemy.move(destination);
```

Instead of a stray module function like:

```zig
pub fn move(enemy: *Enemy, destination: Vector2(i16)) void {
    ...
}
```

The latter is not wrong, but it is less semantically organized.

## 8) Use the right numeric type for the right operation

A common bug is mixing integer and float math.

```zig
const cell = Vector2(i16).init(2, 1);
const pos = cell.times(globals.tile_size);
const world_pos = Vector2(f32).init(
    @floatFromInt(pos.x),
    @floatFromInt(pos.y),
);
```

If you try to negate a `u32`, Zig rejects it because unsigned integers cannot be negative.

This pattern is wrong:

```zig
return Rect(T).init(self.x, self.y, self.w, -self.h);
```

for `T = u32`.

The fix is to convert to `f32` before applying a signed coordinate transform.

## 9) `ArrayList` usage patterns

A common and idiomatic build pattern is:

```zig
var items = try std.ArrayList(u32).initCapacity(allocator, 64);
try items.append(allocator, 5);
```

If you need to store a list as a struct field, keep it as a mutable list value:

```zig
map: std.ArrayList(usize),
```

Then initialize it once and mutate it through its pointer or by binding it as `var`.

## 10) `std.debug.assert` is for invariants, not user input

Use assertions when a value must be valid by design.

```zig
std.debug.assert(settings != null);
```

This is not a substitute for runtime validation of user input or game state.

## 11) Keep the type system honest

Zig strongly prefers matching types exactly.

Common examples:

- `Rect(u32)` is not a `Rect(f32)`
- `u32` cannot be negated
- `*ArrayList(T)` is different from `ArrayList(T)`

When there is a type mismatch, fix the type at the boundary rather than forcing a cast everywhere.

## 12) Typical project pattern for this codebase

This project often follows this pattern:

- `movement` owns transform-related concepts
- `character` and `enemy` own entity behavior
- `input` decides whether movement is legal
- `world` validates cells and walkability
- `rendering` sorts render items by `z_layer`

This keeps responsibilities clear and avoids helper files that merely wrap one method.

## 13) Minimal mental model

If you keep only a few rules in mind, you will avoid most Zig bugs:

- `const` means immutable
- `var` means mutable
- `?T` means optional/nullable
- `null` is the absence value
- `try` propagates errors
- mutation often needs a pointer
- numeric conversions must match the type you need

## 14) Quick examples of correct patterns

### A. Optional settings

```zig
var settings: ?Settings = null;
settings = user_settings;
std.debug.assert(settings != null);
const current_settings = settings.?;
```

### B. Mutable list

```zig
var tiles = try std.ArrayList(usize).initCapacity(allocator, 256);
try tiles.append(allocator, 1);
```

### C. Entity method

```zig
pub const Character = struct {
    position: Position,

    pub fn move(self: *Character, destination: Vector2(i16)) void {
        self.position.cell = destination;
    }
};
```

### D. Float conversion before negative transform

```zig
const rect_f32 = Rect(f32).init(
    @floatFromInt(rect.x),
    @floatFromInt(rect.y),
    @floatFromInt(rect.w),
    @floatFromInt(rect.h),
);
const flipped = rect_f32.flipRectY();
```

## 15) One-line summary

Zig is strict about type correctness and mutation, and the fix is often simply to use `var`, `?T`, `try`, and the correct pointer/type conversion at the right boundary.
