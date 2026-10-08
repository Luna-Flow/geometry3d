# demo design

## Design goal

The terminal demo shows that the library packages compose into a working renderer with very little glue: a scene, a camera, `build_draw_list`, and a backend. It also exercises the parts of the library that a test cannot judge by eye (perspective, lighting, shadows, the dolly zoom, exposure effects) and produces recordings that can be turned into video. Everything that touches the operating system lives here: argument parsing, environment variables, the clock, the terminal and files.

## Constraints

- The demo is the only package allowed to touch the clock, environment variables, the terminal and files.
- The portable standard library has no sleep primitive and no terminal-size query.

## Mathematical background

### The dolly zoom

With the scientific camera, an object of height $Y$ at distance $d$ along the view axis appears $s\,Y/d$ rows tall (before the terminal squeeze), with $s = H f / h$ (see the [view design](view.md)). Keeping the subject's size constant while the camera moves requires

$$
\frac{f(d)}{d} = \frac{f_0}{d_0}
\quad\Longrightarrow\quad
f(d) = f_0 \, \frac{d}{d_0} .
$$

The scenes use these values:

| Scene | Distance $d$ | Base $(d_0, f_0)$ | Focal range |
| --- | --- | --- | --- |
| `--hitchcock` | $5.7 + 2.3 \sin(0.035\,k)$ for frame $k$, in $[3.4, 8]$ | $(4.5, 18\ \text{mm})$ | 13.6–32 mm |
| `--dolly` | $3.2 + 66.365 \cdot \tfrac12\big(1 + \sin(0.028\,k)\big)$, in $[3.2, 69.565]$ | $(3.2, 23\ \text{mm})$ | 23–500 mm |

The far distance of the dolly scene, $69.565\ldots = 3.2 \cdot 500 / 23$, is chosen so that the focal length peaks at exactly 500 mm. An object at distance $d + \Delta$ from the camera, behind the subject, appears scaled by

$$
\frac{s/(d + \Delta)}{s_0/(d_0 + \Delta)} = \frac{d\,(d_0 + \Delta)}{d_0\,(d + \Delta)}
$$

relative to the base view. The factor increases with $d$ towards $(d_0 + \Delta)/d_0$ as $d \to \infty$. The wall of discs stands $\Delta = 5$ units behind the cube, so the limit is $8.2/3.2 \approx 2.56$, and at the far end of the dolly, $d = 3.2 \cdot 500/23$, the wall is

$$
\frac{69.565 \cdot 8.2}{3.2 \cdot 74.565} \approx 2.39
$$

times its base size while the cube stays fixed. The camera on the long end approaches an orthographic projection, which is why the background flattens. Tests check that the subject's projected size ratio stays constant across frames.

### Exposure

The exposure modes approximate the time integral of the image over the shutter interval (see the [frontend design](frontend.md)) with $N = 12$ samples:

$$
\bar L(x) \approx \frac{1}{12} \sum_{j=0}^{11} L\big(x, t - (11 - j)\,\delta\big),
$$

where $\delta$ is one animation step (one frame for the dolly scenes, one rotation increment for the mesh scenes). With `--flow-exposure` each sample $L_j$ is first warped onto the current frame by the block-matching flow $d_j = \text{flow}(L_j, L_{\text{current}})$ with search radius 4 and patch radius 1. `ExposureSettings::auto` is consulted, but it always returns one sample, so the demo's own constant of 12 decides the count.

## Design decisions

### All system access in one package

Reading `COLUMNS` and `LINES`, timing frames, clearing the screen with ANSI escapes, and file I/O through `moonbitlang/x/fs` are the only non-portable operations of the repository, and they all live in `src/demo/main.mbt`. The library packages stay pure and target-independent. The demo loses one row to the shell prompt so that printing a full frame does not scroll.

### A small, forgiving command line

Options are plain flags matched exactly, with a fixed precedence and silent fallbacks. This keeps the parser to a few lines and makes the demo hard to crash from the command line, at the cost of not reporting typos. Numeric options keep only their digits for the same reason.

### Busy-wait frame pacing

The live loops compare `@env.now()` against the last frame time and spin until 33 ms have passed. This needs no sleep primitive, which the portable standard library lacks, and gives stable pacing. The cost is one busy CPU core while the demo runs.

### Streaming recordings

`--record` builds a `TuiSequence` in memory and encodes it at the end, which is simple and exercises the library encoder. `--record-stdout` prints the same format frame by frame, so recordings of thousands of large frames need memory for only one frame; the format's `frames=` header can be written first because the frame count is known from the timeline.

## Correctness and invariants

- The subject of the dolly scenes keeps its projected size: $f/d$ is constant by construction (tested).
- Every frame has exactly the configured width and height, so recordings decode with the sizes in their header.
- A recording's frame count is `Timeline::frame_count()` = $\lceil \mathit{duration} \cdot \mathit{fps} \rceil$.
- Exposure weights sum to 1, so an exposure frame stays within the intensity range of its samples.

## Alternatives rejected

- **An argument-parsing library** would add a dependency for a dozen flags.
- **Raw terminal mode and incremental redraws** would reduce flicker but need platform-specific terminal control.
- **Sleeping between frames** would need FFI on each target.

## Boundaries

The demo does not:

- export any MoonBit API, or run on targets other than `native`;
- read input while running, resize with the terminal, or offer configuration files;
- validate options or report unknown ones;
- render in colour or in the browser (see [demo_canvas](demo_canvas.md) and [demo_gsap](demo_gsap.md)).
