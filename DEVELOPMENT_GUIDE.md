# ZigDungeon: Development Guide

## Project Philosophy

ZigDungeon is intentionally organized as a small, explicit, and testable codebase. The project favors:

- Clear ownership boundaries: the world owns runtime state; engine subsystems own timing, rendering, and allocator lifetimes.
- Small, focused modules: each file represents one responsibility instead of a large monolithic layer.
- Testability: unit tests import production modules directly so behavior is checked against real code paths.
- Predictable runtime flow: update → decide → resolve → render, with minimal hidden state.
- Minimal abstraction for the current scope: keep the architecture understandable and easy to evolve.

This is not a deeply generic engine framework; it is a compact game implementation with a straightforward data flow and explicit dependencies.

## Building

Run commands from the repository root:

```bash
zig build
zig build test
zig build run
```

The build defaults to Debug. Supported options include:

```bash
zig build -Doptimize=ReleaseFast
zig build -Doptimize=ReleaseSafe
zig build -Doptimize=ReleaseSmall
zig build -Draylib-optimize=ReleaseFast
zig build -Dstrip=true
```

The `run` step accepts application arguments:

```bash
zig build run -- arg1 arg2
```

`zig build test` runs the unit-test executable configured in `build.zig`.

## Current Source Layout

```text
src/
├── main.zig                         Application entry point and restart loop
├── engine/
│   ├── engine.zig                    Engine initialization and frame timing
│   ├── core/
│   │   ├── core.zig                  Core subsystem exports
│   │   └── subsystems/
│   │       ├── input.zig             Reusable keyboard state and repeat timing
│   │       ├── gamepad.zig           Gamepad button/axis state and repeat timing
│   │       ├── mouse.zig             Mouse buttons, capture, drag/drop, and viewport tracking
│   │       ├── random.zig            Random number generator
│   │       └── rendering.zig         Render queue and raylib drawing
│   ├── resources/
│   │   ├── MousePointer.zig          Pointer visuals, animation, and renderable creation
│   │   └── sprites/                  Sprite, sprite-sheet, and animation types
│   ├── tiles/                        Tilemap and tileset types
│   ├── utils/                        Engine utilities
│   └── vendors/raylib.zig            raylib binding
├── game/
│   ├── game.zig                      Main game loop and game-over flow
│   ├── setup.zig                     World creation entry point
│   ├── project_settings.zig           Window and game configuration
│   ├── globals.zig                    Assets and shared game constants
│   ├── world.zig                      World state and occupancy queries
│   ├── components/                    Game-specific reusable entity components
│   ├── entity.zig                     Entity IDs and tagged entity data
│   ├── character/                     Player data, input, and resolution
│   ├── npc/
│   │   ├── generic/                   Shared NPC AI, state, planning, and resolution
│   │   ├── soldier/                   Soldier-specific model
│   │   └── slime/                     Slime model and animation configuration
│   ├── combat/                        Health and combat systems
│   ├── movement/                      Positions, transforms, and updates
│   └── rendering/                     Renderable data and render queue systems
└── libs/
    ├── datastructs/                   Data structures
    ├── gfx/                           Color and graphics helpers
    └── maths/                         Geometry, vectors, and transforms
```

Tests live under `tests/`. Game assets are embedded from `src/game/assets/`.

## Main Runtime Flow

`src/main.zig` initializes the engine, creates a `GameWorld`, and calls `game.run`.
Each frame follows this order:

1. Update engine timing.
2. Read player input.
3. Compute NPC plans from the player's position.
4. Resolve NPC actions and player actions.
5. Update world transforms.
6. Queue and render the tilemap and entities.
7. Clear per-frame render and NPC-action queues.

NPC planning does not account for other NPCs. NPC action resolution checks
the destination immediately before moving, so two enemies cannot occupy one cell.

## Key Modules

### World

`src/game/world.zig` owns the tilemap and a fixed-capacity `entities` array.
Each entity's ID is its array index; insertion validates the ID range, slot
availability, and the reserved character slot. The tagged payload keeps
character, soldier, and slime models distinct while world-wide queries and
rendering can traverse the same array. ID 0 is reserved for the character,
followed by separate soldier and slime ID ranges sized to their capacities.
`Entity` owns the common cell, health, force, and parent transform shared by
the character, soldier, and slime. Soldier and slime embed `NPCEntityData`,
which owns their AI state, action plan, and per-entity movement timing and
speeds. Normal and maximum movement speeds default to 1 and 3 cell moves per
second. Wandering and guarding use normal speed; chasing and fleeing use
maximum speed.

The game owns all raylib textures, including generated tileset textures, for
the full application session. `GameWorld.init()` borrows those assets to build
its entities; destroying a world only clears its registry slots. Entity visuals,
animation frames, and mouse pointer configurations hold borrowed texture
handles, so they remain valid across world restarts and while mouse setup is
used outside the gameplay loop. Animation state stores frame rectangles into
the shared spritesheet rather than extracting textures.

### NPCs

- `src/game/npc/generic/ai.zig`: builds the player-distance field and chooses action plans.
- `src/game/npc/generic/action_plan.zig`: stores an NPC's destination for the current turn.
- `src/game/npc/generic/resolution.zig`: applies attacks and movement, including collision checks.
- `src/game/npc/generic/npc_entity_data.zig`: shared NPC state, plans, and movement speeds.
- `src/engine/resources/sprites/AnimatedSprite.zig`: the single generic animated
  sprite type exposed to game clients, including frame configuration, timing,
  animation switching, current-frame access, and renderable creation. Frames
  borrow source textures and identify regions.
- `src/game/entity.zig`: entity ID, type tag, and tagged union of the separate
  character, soldier, and slime models.
- `src/game/npc/soldier/soldier.zig` and `src/game/npc/slime/slime.zig`: separate static
  soldier and animated slime entity models. Both use shared NPC AI and
  combat-resolution rules without one entity model wrapping the other.
- `src/game/npc/slime/slime.zig`: slime model and factory. The factory configures
  its engine `AnimatedSprite` from an `AnimatedSpriteConfig` supplied by the
  caller. Keep the frame rectangles and playback rate in sync with
  `src/game/assets/sprites/enemies/Slime.json`.

### Character and Combat

- `src/game/input.zig`: combines keyboard and gamepad input into game-level actions.
- `src/game/character/input.zig`: translates game-level actions into character
  actions and movement.
- `src/engine/core/subsystems/input.zig`: reusable keyboard press and repeat
  handling; it does not define game-specific actions or movement behavior.
- `src/engine/core/subsystems/gamepad.zig`: reusable gamepad button/axis polling.
- `src/game/character/resolution.zig`: removes the player after death.
- `src/game/combat/components.zig`: defines `Health` and damage/healing behavior.

### Mouse and Pointer

`src/engine/core/subsystems/mouse.zig` provides fixed-size mouse input. It
tracks pointer position, wheel movement, all seven Raylib mouse buttons,
press/release state, double-clicks, viewport enter/leave events, dragging, and
drop events.

`src/engine/resources/MousePointer.zig` provides a generic pointer visual
resource indexed by a client-defined enum. It supports static frames or
fixed-capacity animations, hot reference points, visual offsets, and render
layers; it consumes mouse position but does not poll input. Pointer textures are
borrowed; the client retains ownership.

`src/game/input.zig` owns game-facing mouse input alongside keyboard/gamepad
input: call `updateMouse()` to poll it, query `mouseState()` and
`mouseHotSpotPosition()`, and use `releaseMouseToOS()` or
`requestMouseCapture()` for cursor control. The hot-spot position is in screen
coordinates and is available without a world. `GameWorld.pointedCell(...)`
maps a supplied screen coordinate to a cell when a world exists.

`src/game/rendering/mouse.zig` owns pointer visual configuration and render
queue integration. Initialize it by passing one `PointerConfig` per state, in
the declaration order of the pointer state enum. Static pointers use an
existing `Sprite`, and animated pointers use an existing `AnimatedSprite`.
These sprite resources borrow textures from game-owned `Assets`, which must
outlive the pointer.

### Rendering

`src/engine/core/subsystems/renderer.zig` owns the render queue and z-layer
ordering. Game-specific queueing is in `src/game/rendering/systems.zig`.

```zig
try renderer.addToRenderQueue(z_layer, draw_function, render_pointer);
try renderer.render();
```

### Configuration

Edit `src/game/project_settings.zig` for window size, target FPS, game name, and
random-number-generator configuration.

## Memory and Ownership

This codebase currently uses fixed-size state and static ownership patterns rather
than an allocator-managed lifetime model. `src/main.zig` does not create an arena
or general-purpose allocator; it simply delegates to `game.start()`. The world,
renderer, and related subsystems are stored as fixed-size structs and arrays,
for example `GameWorld.enemies`, `GameTilesMap.map`, and the renderer context
state, and they are scoped to the lifetime of the running process or game loop.

Most game state uses fixed-size storage, but resources backed by raylib GPU
textures still require explicit cleanup. `GameWorld.deinit` releases the
animated slime's extracted frame textures when a game run ends or restarts;
the source spritesheet is released after extraction. Keep such cleanup at the
owning scope and ensure every exit path, including errors, releases owned
resources. Future allocator-backed data (for example `ArrayList` or dynamic
resource caches) should follow allocator-aware Zig APIs and add matching
ownership/deinit logic.

## Allocation and Data-Oriented Design

Avoiding unnecessary allocation is a design goal, especially in per-frame and
other frequently executed code. Prefer fixed-capacity storage when its limits
are known and appropriate. When dynamic storage is needed, allocate or resize
it during initialization or other infrequent operations where practical, and
reuse its capacity rather than allocating temporary collections every frame.
Do not trade correctness or maintainability for a blanket rule against
allocation; make allocation strategy explicit and profile before optimizing.

Keep CPU cache performance in mind when choosing data layout. Prefer compact,
contiguous storage for data that is processed together, and avoid unnecessary
pointer chasing or repeatedly traversing unrelated data in hot loops. For
systems that process many entities in the same way, consider data-oriented
layouts that group the fields used by that system rather than assuming an
object-per-entity layout is always best. Preserve clear ownership and sensible
types, and use profiling to validate that a layout change improves real
workloads.

## Diagnostics

```bash
zig build --verbose
zig build -Doptimize=Debug
```

Use the compiler's reported file and line as the source of truth for Zig errors.
When changing code that allocates or owns heap memory, prefer allocator-aware
APIs and keep lifetime ownership explicit in the current Zig toolchain.

## Build Configuration

`build.zig` defines the executable, the `run` step, and the `test` step. raylib
is included as the `raylib` package dependency in `build.zig.zon` and linked by
the executable.
