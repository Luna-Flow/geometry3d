# TUI Video Export

`tui3d_to_video.py` converts any geometry3d `.tui3d` sequence to video. MP4
outputs use H.264; MOV outputs use ProRes 422 HQ.

## Requirements

- Python 3
- Pillow
- FFmpeg with `libx264` and/or `prores_ks`

## Record A Sequence

For larger recordings, use `--record-stdout` and shell redirection. This keeps
only the current ASCII frame in memory instead of building the full sequence in
a MoonBit `StringBuilder`.

```sh
mkdir -p target
COLUMNS=240 LINES=91 moon run src/demo --target native -- \
  --dolly --record-stdout --duration 12 --fps 24 > target/dolly.tui3d
```

The same command works for other demo modes by replacing `--dolly`, for example
with `--torus` or `--hitchcock`.

## Encode Video

```sh
python3 tools/tui3d_to_video.py target/dolly.tui3d target/dolly.mp4
python3 tools/tui3d_to_video.py target/dolly.tui3d target/dolly.mov
```

The converter reads frames incrementally, displays encoding progress, selects a
common system monospace font, and automatically reduces the font size to stay
within `3840x2160`. Use `--font` when no supported system font is available.

## TUI Aspect Ratio

The TUI renderer applies a `0.5` Y-axis correction, assuming character cells
are twice as tall as they are wide. The video exporter uses the matching `1:2`
cell aspect ratio, so the two transforms cancel physically.

TUI dimensions are columns and rows, not video pixels. A `240x90` grid has a
physical ratio of `240:(90 * 2)`, or 4:3. A `480x360` grid produces a 2:3
portrait frame.

Useful options:

```sh
python3 tools/tui3d_to_video.py input.tui3d output.mp4 \
  --font /path/to/monospace.ttf \
  --font-size 18 \
  --cell-aspect 2 \
  --max-width 3840 \
  --max-height 2160 \
  --no-progress
```
