# ZigDungeon: Development Guide

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
│   │   ├── random.zig                Random number generator
│   │   └── subsystems/
│   │       ├── gametimer.zig         Frame timer
│   │       ├── inputs.zig            Input state
│   │       └── renderer.zig          Render queue and raylib drawing
│   ├── sprites/                      Sprite and sprite-sheet types
│   ├── tiles/                        Tilemap and tileset types
│   ├── utils/                        Engine utilities
│   └── vendors/raylib.zig            raylib binding
├── game/
│   ├── game.zig                      Main game loop and game-over flow
│   ├── setup.zig                     World creation entry point
│   ├── project_settings.zig           Window and game configuration
│   ├── globals.zig                    Assets and shared game constants
│   ├── world/world.zig                World state and occupancy queries
│   ├── character/                     Player data, input, and resolution
│   ├── enemy/                         Enemy data, AI, plans, and resolution
│   ├── combat/                        Health and combat systems
│   ├── movement/                      Positions, transforms, and updates
│   └── rendering/                     Renderable data and render queue systems
└── libs/
    ├── datastructs/                   Data structures
    ├── gfx/                           Color and graphics helpers
    └── maths/                         Geometry, vectors, and transforms
```

Tests live under `tests/`. Assets used by the game are under `src/assets/`.

## Main Runtime Flow

`src/main.zig` initializes the engine, creates a `GameWorld`, and calls `game.run`.
Each frame follows this order:

1. Update engine timing.
2. Read player input.
3. Compute enemy plans from the player's position.
4. Resolve enemy actions and player actions.
5. Update world transforms.
6. Queue and render the tilemap and entities.
7. Clear per-frame render and enemy-action queues.

Enemy planning does not account for other enemies. Enemy action resolution checks
the destination immediately before moving, so two enemies cannot occupy one cell.

## Key Modules

### World

`src/game/world/world.zig` owns the tilemap, optional player, enemy list, and
pathfinding work buffer. It also provides `isCellWalkable` and
`isCellOccupiedByOtherEnemy` for movement and collision checks.

### Enemy

- `src/game/enemy/ai.zig`: builds the player-distance field and chooses an action plan.
- `src/game/enemy/action_plan.zig`: stores an enemy's destination for the current turn.
- `src/game/enemy/resolution.zig`: applies attacks and movement, including collision checks.
- `src/game/enemy/enemy.zig`: enemy data, creation, movement, and damage handling.

### Character and Combat

- `src/game/character/input.zig`: converts input into movement or attacks.
- `src/game/character/resolution.zig`: removes the player after death.
- `src/game/combat/components.zig`: defines `Health` and damage/healing behavior.

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

`src/main.zig` uses an arena allocator for the application lifetime. The world
owns its enemy list, work buffer, tilemap, and entity sprites, and releases them
through `GameWorld.deinit`. The engine releases renderer and random-generator
resources through `engine.deinit`.

## Diagnostics

```bash
zig build --verbose
zig build -Doptimize=Debug
```

Use the compiler's reported file and line as the source of truth for Zig errors.
When changing `ArrayList` code, follow the allocator-aware APIs used in the
current Zig toolchain.

## Build Configuration

`build.zig` defines the executable, the `run` step, and the `test` step. raylib
is included as the `raylib` package dependency in `build.zig.zon` and linked by
the executable.
