# ZigDungeon

ZigDungeon is a dungeon game made with [raylib](https://www.raylib.com/). It is
a port to Zig 0.16.0-dev and a data-oriented rework of an earlier
object-oriented Zig game by MrBSmith, also known as Babadesbois 💛.

## Prerequisites

- [Zig 0.16.0-dev](https://ziglang.org/download/)
- [Raylib 6.0](https://github.com/raysan5/raylib/releases/tag/6.0)
- [Git](https://git-scm.com/downloads)

## Installation

Clone ZigDungeon and its local Raylib source dependency, then apply the
project's Raylib build patch:

```bash
git clone https://github.com/bsil78/ZigDungeon.git
cd ZigDungeon
git clone --depth 1 --branch 6.0 https://github.com/raysan5/raylib.git raylib
```

## Raylib Build Patch

Raylib is built from the local `raylib` source directory by Zig as part of the
game build, so a separately installed Raylib library is not required. Before
building, run the patch-only build command from the repository root:

```bash
zig build -Dpatch-raylib=true
```

This applies `raylib-no-emsdk.patch` to the local Raylib checkout without
resolving the Raylib build dependency first. It is safe to run more than once.

The patch disables Raylib's Emscripten build integration and marks its
Emscripten SDK packages as lazy dependencies. This prevents a normal
desktop build from downloading or installing Emscripten tooling. It also
creates Raylib's optional `emsdk.zig` helper; the patched build leaves the
Emscripten integration disabled, so desktop builds do not import that helper.
Emscripten targets are not supported by this patched configuration.

## Launching the Game

From the repository directory:

```bash
zig build run
```

The command builds the game when necessary and launches the ZigDungeon window.

For build configuration, source organization, testing, and development
workflow, see [DEVELOPMENT_GUIDE.md](DEVELOPMENT_GUIDE.md).

## License and Credits

The project is a Zig and raylib rework of the original ZigDungeon game by
MrBSmith. raylib is provided through the repository dependency configuration.

## Troubleshooting

If the patch command reports that Raylib cannot be found, ensure the Raylib
6.0 checkout is located at `raylib` under the ZigDungeon repository root.
If applying the patch fails, check that the checkout is Raylib 6.0 and that
its build files have not been modified incompatibly.
