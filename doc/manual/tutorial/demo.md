# demo tutorial

This tutorial shows you how to run the terminal demo of the repository: the animated scenes, the exposure effects, recording and playback, still images and video export. You need a clone of the repository and a native MoonBit toolchain; no code is written.

## Quick start

From the repository root, render one frame of the sphere scene into a 48 × 14 frame:

```sh
COLUMNS=48 LINES=15 moon run src/demo --target native -- --sphere --once
```

Output (after the escape sequence that clears the screen):

```text
................................................
................................................
................................................
................................................
....................*#%%%%@@....................
..................=+**##%%%%@@..................
................. -+**####%%%%#.................
................. :=++**#######.................
..................:-==++******..................
.....................-====+=....................
................................................
................................................
................................................
................................................
```

The sphere is lit from the upper right; its lower left faces turn away from the light and are drawn with the darkest characters. Drop `--once` to keep the demo running, and stop it with Ctrl-C.

## Everyday tasks

### Watch the animated scenes

The `just` recipes measure the terminal and pass its size to the demo:

```sh
just cube        # spinning cube (the default scene)
just torus       # spinning torus
just hitchcock   # dolly zoom with a central cube and background shapes
just dolly       # dolly zoom against a wall of discs
```

Without `just`, set `COLUMNS` and `LINES` yourself, for example `COLUMNS=$(tput cols) LINES=$(tput lines) moon run src/demo --target native -- --torus`.

### Add motion blur

`--long-exposure` averages twelve renders of the preceding motion into each frame; `--flow-exposure` aligns them with optical flow first, which keeps edges sharper:

```sh
moon run src/demo --target native -- --hitchcock --long-exposure
moon run src/demo --target native -- --torus --flow-exposure
```

Exposure frames cost about twelve times as much as plain ones (and flow alignment considerably more), so they run slower in large terminals.

### Record and play a sequence

```sh
mkdir -p target
moon run src/demo --target native -- --torus --record target/torus.tui3d --duration 4 --fps 24
moon run src/demo --target native -- --play target/torus.tui3d
```

`--record` renders all frames first and writes the file at the end. For long recordings stream the frames instead:

```sh
COLUMNS=240 LINES=91 moon run src/demo --target native -- \
  --dolly --record-stdout --duration 12 --fps 24 > target/dolly.tui3d
```

### Export and show a still image

```sh
moon run src/demo --target native -- --hitchcock --export-image target/hitchcock.tuiimg
moon run src/demo --target native -- --show-image target/hitchcock.tuiimg
```

`just export-image` and `just show-image` do the same for the default scene.

### Turn a recording into a video

```sh
python3 tools/tui3d_to_video.py target/dolly.tui3d target/dolly.mp4
```

The converter needs Python 3, Pillow and FFmpeg; see [`tools/README.md`](../../../tools/README.md).

## Going further

The demo is a thin layer over the library: every frame is `@frontend.build_draw_list` followed by `@tui.render_frame`, and the exposure modes use `@tui.draw_list_to_tui_luma`, `LumaBuffer::add_weighted_sample` and `estimate_optical_flow`. Read `src/demo/main.mbt` next to the [TUI tutorial](backend/tui.md) to build your own player. The browser versions of the torus and dolly scenes are in [demo_canvas](demo_canvas.md) and [demo_gsap](demo_gsap.md).

## Common pitfalls

- **Native target.** The demo reads the clock, the environment and files; run it with `--target native`.
- **Terminal size.** Without `COLUMNS` and `LINES` the demo uses 80 × 32, which may scroll in a smaller terminal. Many shells do not export these variables to child processes; the `just` recipes set them.
- **Integer options.** `--duration` and `--fps` take whole numbers; the parser keeps only the digits, so `0.5` becomes `5`.
- **Unknown options are ignored.** A misspelt option silently falls back to the spinning cube.
- **CPU use.** The live loops poll the clock between frames and keep one core busy.

## Next steps

- The [demo API](../api/demo.md) lists every option and the order in which modes take precedence.
- The [demo design](../design/demo.md) derives the dolly zoom and explains the exposure modes.
- The [TUI tutorial](backend/tui.md) shows the library calls behind the demo.
