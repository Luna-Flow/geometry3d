# demo API

`Luna-Flow/geometry3d/demo` is an executable, not a library: it exports no MoonBit items. Its interface is the command line described here. It renders animated scenes into the terminal with the [TUI backend](backend/tui.md), and records, plays, exports and shows `.tui3d` sequences and `.tuiimg` images. It is meant for the `native` target, which provides the clock, the environment and the file system it uses.

```sh
moon run src/demo --target native -- [options]
```

Options are matched exactly; unknown options are ignored. The [demo tutorial](../tutorial/demo.md) shows typical sessions and the [demo design](../design/demo.md) explains the scenes.

## Environment

### `COLUMNS`, `LINES`

The frame is `COLUMNS` cells wide and `LINES - 1` rows high; one row is left for the shell prompt. Missing or unreadable values give 80 × 32. The `just` recipes of the repository set both from `stty size`.

## Scenes

Without a scene option the demo spins a cube of half-size 1.

### `--sphere`

`--sphere` shows a static UV sphere of radius 2.4 with 18 rings and 36 segments.

### `--torus`

`--torus` spins a torus with radii 2.1 and 0.72 and 28 × 16 segments, seen from 6.8 units away.

### `--hitchcock`

`--hitchcock` shows a central cube in front of cylinders, cones and a triangular pyramid while the camera dollies between 3.4 and 8 units away and the focal length follows the distance, so the cube keeps its size and the background changes scale.

### `--dolly`

`--dolly` shows a spinning cube in front of a wall of 5 × 7 discs while the camera dollies between 3.2 and about 69.6 units and the focal length grows from 23 mm to 500 mm.

The mesh scenes (cube, sphere, torus) use an 18 mm lens on a full-frame sensor, 4.5 units away unless stated otherwise.

## Effects

### `--long-exposure`

`--long-exposure` averages 12 renders of the preceding motion into each frame, which blurs moving edges.

### `--flow-exposure`

`--flow-exposure` is `--long-exposure` with each earlier render first aligned to the current one by block-matching optical flow (search radius 4, patch radius 1).

## Running

### `--once`

`--once` renders a single frame (or plays a single frame of a sequence) and exits. Without it, the live modes run until interrupted, at one frame per 33 ms.

## Files

### `--record PATH`

`--record PATH` renders a whole sequence for the selected scene and effects and writes it to `PATH` as `.tui3d`.

### `--record-stdout`

`--record-stdout` writes the same `.tui3d` text to standard output frame by frame, without keeping the sequence in memory. Redirect it to a file for long recordings.

### `--duration SECONDS`, `--fps N`

These options set the length (default 3 s) and frame rate (default 30) of `--record` and `--record-stdout`. Both take positive integers: the parser keeps only the digits of the argument, so `--duration 0.5` means 5 seconds.

### `--play PATH`

`--play PATH` reads a `.tui3d` file and plays it in the terminal at its recorded frame rate (the nearest of 60, 30, 24, 12 or 10 frames per second, rounded down).

### `--export-image PATH`

`--export-image PATH` renders one still of the selected scene and effects and writes it to `PATH` as `.tuiimg`.

### `--show-image PATH`

`--show-image PATH` reads a `.tuiimg` file and prints it.

## Precedence

When several modes are given, the first that applies wins, in this order: `--record-stdout`, `--show-image`, `--export-image`, `--play`, `--record`, `--dolly`, `--hitchcock`, then the mesh scenes. A file that cannot be read or written aborts the program with a message naming the path.
