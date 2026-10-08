# backend/canvas design

## Design goal

The Canvas backend shows the same `DrawList` as the terminal backend in a browser, at pixel resolution and in colour, with exact occlusion. It should reuse the frontend's software depth buffer instead of growing a second rasterizer, and keep the number of DOM calls per frame small, because each call from MoonBit into the Canvas API crosses the JavaScript boundary.

## Constraints

- The package runs only on the `js` target and reaches the Canvas 2D API through `moonbit-community/rabbita/dom`.
- Every call into the DOM crosses the JavaScript boundary, so the number of calls per frame matters more than the arithmetic.

## Mathematical background

### From intensity to colour

Each covered pixel has an intensity $I$ from the depth-tested `LumaBuffer`. The backend quantizes it to one of $L$ shade levels and scales the foreground colour $\mathbf{c} = (r, g, b)$ by the level:

$$
q = \operatorname{round}\big(\operatorname{clamp}_{[0,1]}(I)\,(L - 1)\big),\qquad
\mathbf{c}_q = \operatorname{round}\!\left(\mathbf{c}\,\frac{q}{L - 1}\right).
$$

As for the TUI ramp, the quantization error of the intensity is at most $1/(2(L - 1))$; with the default $L = 256$ that is below the resolution of an 8-bit channel, so the result is visually continuous. The scaling is linear in the stored channel values. Displays apply the sRGB transfer curve, under which the emitted luminance grows roughly like the stored value to the power 2.2, so mid intensities look darker than a physically linear rendering would. This matches the look of the TUI ramp and is not corrected.

The background is a separate colour, not shade 0. A covered pixel with $I = 0$ (a face turned away from the light) is painted pure black and stays distinguishable from the background; the `LumaBuffer` depth, not the value, decides what is covered (depth below `LUMA_FAR_DEPTH / 2`).

### Run-length painting

Painting pixel by pixel would cost one `fillRect` per pixel. The backend instead scans each row and groups maximal runs of consecutive covered pixels with the same shade $q$:

$$
\text{row } y:\quad [x_0, x_1), [x_1', x_2), \dots \quad\text{with } q \text{ constant on each run and different (or a gap) between neighbours.}
$$

Painting each run as one rectangle of height 1 produces exactly the same image as painting every covered pixel. The runs are disjoint, their union is the set of covered pixels of the row, and every pixel of a run receives the colour $\mathbf{c}_q$ of its own shade. The number of rectangles is the number of runs, at most the number of covered pixels and usually far smaller, because a flat-shaded face has one intensity and spans whole runs. The fill style is set only when the shade differs from the previous run's, so a large face of one shade costs one style change per row at most.

### Occlusion

Visibility comes from the frontend's depth buffer, whose invariant is derived in the [frontend design](../frontend.md#the-depth-buffer): every pixel shows a covering triangle within `DEPTH_EPSILON` of the nearest one, independent of draw order except among such near-ties. The Canvas output is therefore exact per pixel, unlike the painter's ordering of the [GSAP SVG backend](gsap.md).

## Design decisions

### Reuse the frontend rasterizer

The Canvas 2D API can fill polygons itself, but it has no depth buffer, so occlusion would need sorting and would fail for intersecting triangles. Rasterizing into `LumaBuffer` gives exact occlusion and the same perspective-correct depth as the TUI backend, at the cost of doing the per-pixel work in MoonBit. At 640 × 480 this is fast enough for the animated demos.

### One colour, many shades

A single foreground colour scaled by intensity keeps the frontend's contract (a scalar intensity per triangle) and reproduces the monochrome look of the terminal version in colour. Materials and per-object colours would require extending `DrawTriangle`.

### Runs instead of `ImageData`

Writing an `ImageData` buffer and calling `putImageData` once would cost one DOM call per frame, but needs a typed-array binding and per-pixel writes on the JavaScript side. Run-length `fillRect` calls use only the stable 2D context API exposed by `rabbita/dom` and are cheap for flat-shaded scenes, whose runs are long.

### Normalize on every call

The configuration is normalized again inside every render call. A configuration built by any route (including by code inside this package) cannot make the renderer divide by zero or emit an invalid CSS colour.

## Correctness and invariants

- Every pixel of the configured area is painted: first with the background, then covered pixels with their shade.
- Painting runs is pixel-for-pixel equal to painting covered pixels individually.
- Each covered pixel shows the nearest triangle (frontend depth-buffer invariant).
- Channels are always within $[0, 255]$ and `shade_levels` within $[2, 256]$ after normalization.

The cost per frame is the frontend rasterization plus one $O(W H)$ scan for runs, plus one `fillRect` per run.

## Alternatives rejected

- **WebGL.** It would move rasterization to the GPU, but needs shaders and buffers and would duplicate the pipeline that the frontend already implements in MoonBit.
- **Polygon fills sorted by depth.** Fewer calls, but painter's ordering is wrong for intersecting or cyclically overlapping triangles; the SVG backend accepts that trade-off, the Canvas backend does not.
- **Gamma-correct shading.** It would change the look relative to the terminal output, which is the reference picture of the repository.

## Boundaries

The Canvas backend does not:

- run on targets other than `js`, or work without a DOM;
- schedule animation frames, read input, or look up elements (the `demo_canvas` package does);
- support per-object colours, textures, transparency, anti-aliasing or GPU acceleration;
- let callers change colours or shade levels from outside the package: `CanvasRenderConfig` fields are read-only there, and only `default` and `sized` construct it;
- apply any aspect-ratio correction (canvas pixels are square).
