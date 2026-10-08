# backend/tui design

## Design goal

The TUI backend shows the frontend's triangles in a terminal, using only characters. A terminal cell is a coarse, non-square pixel with no colour in this backend, so the package has three jobs: correct the cell shape so that a cube looks like a cube, map a continuous intensity onto a handful of characters, and resolve occlusion per cell. It should produce plain strings that tests, files and video tools can consume, and stay free of ANSI escape codes and terminal I/O, which belong to the demo.

## Constraints

- A terminal cell is a coarse pixel about twice as tall as it is wide, with one character and, in this backend, no colour.
- The output must be plain strings that tests, files and the video exporter can consume on every target.

## Mathematical background

### Non-square cells

The frontend projects into a grid of square units: one unit of $x$ and one unit of $y$ have the same physical length. A typical terminal cell is about twice as tall as it is wide. If the projection's $y$ were used directly as a row index, every shape would appear stretched vertically by the cell aspect ratio $\kappa = h_{\text{cell}} / w_{\text{cell}} \approx 2$. Measuring physical lengths in cell widths, a vertical segment of $\Delta y$ units must cover $\Delta y / \kappa$ rows. `apply_terminal_y_scale` applies this scale about the middle row so that the image stays centred:

$$
y' = \frac{H}{2} + \left(y - \frac{H}{2}\right) k,\qquad k = \frac{1}{\kappa} = 0.5 .
$$

$x$ and the depth are unchanged. The map is affine in screen coordinates, so it preserves barycentric coordinates and hence the perspective-correct depth rule of the [view design](../view.md): interpolating $1/z$ after the squeeze gives the same depth as before it.

### Field of view in a terminal

With a `ScientificCamera`, the projection scale $s = H f / h$ makes the vertical angle of view span $H$ units, which the squeeze turns into $H/2$ rows. The image is undistorted, but the vertical field of view occupies the middle half of the rows. Equivalently, the full height of the terminal shows a vertical angle of

$$
2 \arctan\!\left(\frac{H/2}{k\,s}\right) = 2 \arctan\frac{h}{f}
$$

instead of $2 \arctan\big(h / (2f)\big)$. The demos choose their focal lengths with this in mind. The video exporter in `tools/` renders cells with the same $1 : 2$ aspect ratio, so the two transforms cancel physically.

### Shade quantization

A ramp of $n$ characters $c_0 \dots c_{n-1}$, ordered by how much ink they put in a cell, represents intensities by rounding to the nearest of $n$ equally spaced levels:

$$
i(I) = \operatorname{round}\big(\operatorname{clamp}_{[0,1]}(I)\,(n - 1)\big),\qquad
\left| \frac{i(I)}{n - 1} - I \right| \le \frac{1}{2(n - 1)} \quad (0 \le I \le 1).
$$

The default ramp `" .:-=+*#%@"` has $n = 10$, so the quantization error is at most $1/18 \approx 0.056$. Intensity $0$ maps to the first character, a space, so an unlit face is still drawn and still hides what is behind it. Intensities slightly above 1 from floating-point rounding are clamped.

### Rasterization and depth

`draw_triangle_z` uses the edge-function rule and the depth invariant derived in the [frontend design](../frontend.md): a cell is covered when its centre $(x + \tfrac12, y + \tfrac12)$ lies in the closed triangle, the depth there is $\big(\sum \lambda_i / z_i\big)^{-1}$, and a write happens only if it is nearer than the stored depth by more than `DEPTH_EPSILON`. After all triangles are drawn, each cell shows the character of a covering triangle whose depth is within `DEPTH_EPSILON` of the nearest one; only the choice among such near-ties depends on the draw order.

### Two rendering paths

The direct path (`render_draw_list`) chooses a character per triangle and rasterizes characters. The luma path (`draw_list_to_tui_luma` followed by `render_luma_buffer`) rasterizes intensities into a frontend `LumaBuffer` first and quantizes per cell afterwards. For a single frame both give the same characters on lit surfaces. They differ in two ways:

- The luma path quantizes *after* any processing. Averaging $N$ exposures before quantizing yields intermediate shades that averaging characters could not.
- The luma path draws only cells whose value is above $0$, so unlit faces show the background pattern instead of a space.

### File formats

Both formats are line-oriented text:

```text
GEOMETRY3D_TUI_SEQUENCE v1        GEOMETRY3D_TUI_IMAGE v1
width=W                           width=W
height=H                          height=H
fps=F                             ---image---
frames=N                          <H lines>
---frame---
<H lines>
---frame---
<H lines>
...
```

The decoders split on `'\n'`, drop `'\r'`, read the digits after `=` on the header lines (falling back to the defaults), and take the $H$ lines that follow each marker. Round trip: if every frame's content consists of exactly $H$ lines, each terminated by `'\n'`, containing no `'\r'`, then `decode(encode(s))` has the same size, frame rate and frame contents as `s`. The encoder writes the header, then each marker followed by those $H$ lines verbatim, and the decoder reads back exactly the $H$ lines after each marker and re-terminates them. The `frames=` count is informational; the decoder counts markers instead, which lets `--record-stdout` stream frames without knowing their number in advance.

## Design decisions

### Aspect correction in the backend

Non-square cells are a property of the output device, not of the scene or the camera, so the correction lives here and nowhere else. `core`, `view` and `frontend` keep square units, and the Canvas and SVG backends, whose pixels are square, need no correction. The factor is a configuration field so that terminals with other cell shapes can be supported by the package.

### One character per triangle

Each triangle has one flat intensity, so the direct path picks its character once and rasterizes characters. This is the cheapest correct choice for flat shading. The luma path exists for the cases that need arithmetic on intensities before quantization.

### Patterns as functions

A background is a function of the cell position and the buffer size, so dots, checkerboards, borders or gradients are all one-liners and need no stored image. `dotted_background` is the default because it shows the extent of the frame in a terminal, where trailing spaces are invisible.

### Strings, not terminal I/O

The package returns `String` values and never prints. Clearing the screen, timing, reading `COLUMNS`/`LINES` and writing files are the demo's business, which keeps the backend usable in tests (behavioural assertions instead of brittle full-frame snapshots) and on every MoonBit target.

### Lenient, plain-text file formats

The formats are readable in a text editor, diffable, and trivially parsed by the Python video exporter. The decoders never fail; they fall back to defaults, because their only consumer, the demo player, prefers showing something to aborting.

## Correctness and invariants

- `FrameBuffer::to_string` has exactly `height * (width + 1)` characters.
- `shade_char` returns a ramp character for every input; its error is at most $1/(2(n - 1))$ on $[0, 1]$.
- The vertical squeeze preserves perspective-correct depth, so occlusion is the same with and without it.
- Each cell shows a covering triangle within `DEPTH_EPSILON` of the nearest covering depth; background cells keep depth `FAR_DEPTH`.
- Sequences and images round-trip under the condition stated above.

The cost of drawing a triangle is proportional to the area of its bounding box in cells. The box is not clipped to the buffer, so a huge off-screen triangle (from geometry close to the eye) costs time even though it writes nothing.

## Alternatives rejected

- **ANSI colour or Unicode block and Braille characters.** They give more resolution or colour, but depend on terminal capabilities and fonts. A pure ASCII ramp works everywhere, including in files and in the video exporter.
- **Correcting the aspect ratio in the projection.** A non-uniform projection scale would leak a device property into `view` and into every other backend.
- **Dithering.** Error diffusion would add texture to flat faces; with ten levels, faceted shading is already legible.
- **Binary or compressed file formats.** Text keeps the files inspectable and the tools simple; recordings compress well with general-purpose tools if needed.

## Boundaries

The TUI backend does not:

- print, clear the screen, read terminal size or environment variables, or measure time;
- emit ANSI escape codes, colour, or Unicode block characters;
- clip triangles to the buffer, anti-alias, or dither;
- validate that file contents match the declared width;
- let callers change the ramp, background or scale through `TuiRenderConfig` from outside the package (its fields are read-only); the lower-level functions cover those cases.
