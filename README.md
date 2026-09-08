# ZigDungeon

ZigDungeon is a dungeon game made with [raylib](https://www.raylib.com/). It is
a port to Zig 0.16.0-dev and a data-oriented rework of an earlier
object-oriented Zig game by MrBSmith, also known as Babadesbois 💛.

## Prerequisites

- [Zig 0.16.0-dev](https://ziglang.org/download/)
- [Git](https://git-scm.com/downloads)

## Installation

Clone the repository and initialize its raylib dependency:

```bash
git clone https://github.com/bsil78/ZigDungeon.git
cd ZigDungeon
git submodule update --init --recursive
```

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

If Git cannot download the raylib dependency, check your Git authentication
configuration or use HTTPS URLs for the repository and its submodules.
