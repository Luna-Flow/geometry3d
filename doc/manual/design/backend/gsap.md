# backend/gsap design

## Design goal

The GSAP backend shows a `DrawList` as resolution-independent vector graphics and lets a mature animation library, GSAP, own playback: play, pause, reverse, seek, speed and looping. The scene math stays in MoonBit; JavaScript only stores polygons and runs the clock. The backend has no depth buffer, because SVG has none, so it must decide visibility by drawing order. This page states when that order is exact.

## Constraints

- SVG has no depth buffer: occlusion can only come from the order of the elements.
- GSAP is loaded by the page, not by MoonBit, and is found at `globalThis.gsap`.
- The package runs only on the `js` target.

## Mathematical background

### Painter's algorithm

SVG paints its children in document order, each covering what was painted before. If triangles are emitted from far to near, nearer surfaces cover farther ones. The backend uses the mean camera-space depth of each triangle as its sort key,

$$
\bar z(T) = \tfrac13 (z_0 + z_1 + z_2),
$$

sorted in decreasing order, with ties broken by the position in the draw list, so the result is deterministic.

**When the order is exact.** Two triangles whose screen projections do not overlap can be drawn in any order. For overlapping ones, the order is correct if the nearer triangle is drawn later. A sufficient condition is that their depth ranges are disjoint: if $\max_i z_i(A) < \min_i z_i(B)$, then $\bar z(A) < \bar z(B)$, so $B$ is drawn first and $A$, the nearer one everywhere, covers it.

**A single convex object is always exact.** Let the mesh bound a convex solid and let the frontend have removed the back faces. A ray from the eye through a pixel meets the boundary of a convex solid in at most two points, entering through a front face and leaving through a back face. So at most one *front* face lies on each ray, and the projections of distinct front faces overlap at most along shared edges. Every drawing order is then correct, and in particular the sorted one. Cubes, spheres, cylinders, cones and the pyramid are convex.

**Where it fails.** For non-convex meshes (the torus) and scenes of several objects, overlapping triangles can have overlapping depth ranges. Mean depth is then a heuristic, and two configurations defeat any ordering of whole triangles:

- *cyclic overlap*: $A$ covers part of $B$, $B$ part of $C$, and $C$ part of $A$;
- *interpenetration*: two triangles intersect, so each is in front of the other on one side of the intersection line.

Correct results would need splitting triangles (Newell's algorithm) or a depth buffer. The [Canvas backend](canvas.md) has a depth buffer and is exact in these cases.[^newell]

[^newell]: M. E. Newell, R. G. Newell and T. L. Sancha, "A solution to the hidden surface problem", Proc. ACM National Conference, 1972.

### Shading

Fills use the same quantization as the Canvas backend: $q = \operatorname{round}(\operatorname{clamp}(I)\,(L - 1))$ and colour $\operatorname{round}(\mathbf{c}\, q / (L - 1))$, with error at most $1/(2(L - 1))$ in intensity.

### Time as the only input

`GsapPlayer` tweens a clock object from $0$ to $D$ seconds with a linear ease. For timeline position $\tau$ (in GSAP's own time, already scaled by the speed factor), the callback receives $t = \tau$ for $\tau \in [0, D]$. The MoonBit side renders the scene as a pure function of $t$: $\text{frame}(t) = \text{render}(\text{scene}(t))$. Seeking, reversing, looping and changing speed therefore need no extra state: whatever $t$ GSAP reports, the picture for that $t$ is drawn. Updates arrive at the browser's refresh rate, not at a fixed frame rate, so the backend never assumes a frame interval.

## Design decisions

### Vector output with painter's ordering

The problem: produce crisp, scalable output that a browser can retain and restyle, from triangles. SVG polygons are exactly that, but SVG has no depth buffer. The options were to rasterize into an image (losing the vector benefits), split triangles to obtain an exact order (complex and slow in the general case), or sort whole triangles. Sorting was chosen: it is exact for the convex primitives of the library, close to correct for typical scenes, and cheap at $O(n \log n)$.

### Mean depth as the key, stable ties

Mean depth is cheap and symmetric in the vertices. Breaking ties by the original index makes the output deterministic, so tests can assert the exact polygon order, and frames of a static scene do not flicker.

### Reusing DOM nodes

Each call reuses the existing `<polygon>` elements and only adds or removes the difference in count. Creating thousands of elements per frame would dominate the cost and stress the garbage collector; updating two attributes per polygon does not. The markers `data-gsap-svg-background` and `data-gsap-svg-triangles` let the backend find its own nodes, and it replaces the children of an `<svg>` that does not have them yet.

### GSAP owns the clock

Playback controls are solved problems in GSAP. The backend exposes a minimal, clamped subset (`seek` within the duration, `set_progress` within $[0, 1]$, a positive time scale, repeat $\ge -1$) so that MoonBit callers cannot drive the timeline into states the demo UI does not expect. GSAP is looked up at `globalThis.gsap` at construction time rather than imported, so the page decides how to load it (CDN, bundler, or a local copy).

## Correctness and invariants

- After `render_draw_list`, the triangle group has exactly as many polygons as the draw list has triangles, ordered by decreasing mean depth with stable ties.
- The picture is exact whenever overlapping triangles have disjoint depth ranges, in particular for any single convex mesh after back-face culling.
- Fill colours are valid `rgb(r, g, b)` strings with channels in $[0, 255]$.
- `GsapPlayer` keeps $\text{seek} \in [0, D]$, $\text{progress} \in [0, 1]$, time scale $> 0$ and repeat $\ge -1$ for values passed through its methods.

Cost per frame: the frontend pipeline, an $O(n \log n)$ sort of $n$ triangles, and $O(n)$ attribute updates.

## Alternatives rejected

- **Per-pixel depth in SVG** (for example one polygon per pixel run) gives up everything SVG is good at.
- **BSP trees or Newell's algorithm.** Both give exact orders, but split triangles and change the polygon count from frame to frame; for demo scenes the visible errors of mean-depth sorting are rare and short-lived.
- **Driving `requestAnimationFrame` from MoonBit.** It would reimplement play, pause, reverse and seek, which GSAP already provides.

## Boundaries

The GSAP backend does not:

- run on targets other than `js`, or work without a DOM and a global `gsap`;
- resolve cyclic overlaps or intersecting triangles;
- add strokes to hide the hairline anti-aliasing seams that can appear between adjacent polygons;
- build the player UI, load GSAP, or choose what to render at a given time (the `demo_gsap` package does);
- let callers change colours or shade levels from outside the package (the configuration fields are read-only there).
