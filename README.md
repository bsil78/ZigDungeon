# ZigDungeon

A port to Zig 0.15.2 of a dungeon game made with Zig and Raylib by MrBSmith alias Babadesbois 💛

## Prerequisites

- [Zig](https://ziglang.org/) (0.15.2)
- Git
- SSH key configured with GitHub eventually (for raylib notably)

## Getting Started

After having:
1. Cloned the repository and moved into its directory:
   ```
   git clone https://github.com/bsil78/ZigDungeon.git
   cd ZigDungeon
   ```

2. Set up raylib as a submodule:
   ```
   git submodule init
   git submodule update
   ```

3. Built the project:
   ```
   zig build
   ```

### Build Options

| Option | Command | Description |
|--------|---------|-------------|
| Debug (default) | `zig build -Doptimize=Debug` | Build with debug symbols |
| Release | `zig build -Doptimize=ReleaseFast` | Optimized release build |
| Strip symbols | `zig build -Dstrip=true` | Reduce binary size |

## Running the Game

After building, run the game using:
```
zig build run
```

This command will:
- Build the project if needed
- Install required assets
- Launch the game

You should see a window appear with "Welcome to ZigDungeon!" displayed, indicating successful setup.

## Project Structure

```
ZigDungeon/
├── src/              # Source code directory
│   └── main.zig     # Entry point
├── build.zig        # Zig build script
├── build.zig.zon    # Dependencies declaration
└── .gitmodules      # Git submodules configuration
```

## Dependencies

- [raylib](https://github.com/raysan5/raylib) - Game development library
  - Automatically managed through build.zig.zon
  - Included as a git submodule


## Running Tests

```
zig build test
```

## Troubleshouting

### If you have trouble with git downloads 

Consider using https addresses for example, replace raylib one in .gitmodules eventually.