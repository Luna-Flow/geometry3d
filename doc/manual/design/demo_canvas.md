# demo_canvas design

## Design goal

`demo_canvas` shows the Canvas backend on a real page with as little browser code as possible: one canvas, one selector, one animation loop. It reuses the scenes of the terminal demo, so the two outputs can be compared directly.

## Constraints

- The program runs in a browser page it does not create: the elements it needs must be present in `index.html`.
- It may only use the public API of the library packages and `rabbita`.

## Mathematical background

### Time from animation frames

`requestAnimationFrame` passes a timestamp $\tau$ in milliseconds since the page started. The torus scene turns by the angle $\theta = 0.0006\,\tau$, so one full turn about $y$ takes $2\pi / 0.0006 \approx 10.5$ seconds, independent of the display's refresh rate. The dolly scene is defined per frame of the terminal demo, so the page converts time into a frame number at 30 frames per second,

$$
k = \left\lfloor \frac{\tau}{1000/30} \right\rfloor ,
$$

and renders frame $k$. On a 60 Hz display each dolly frame is shown twice; the motion runs at the same speed as in the terminal.

### Framing

The canvas is 640 × 480 (4:3) and the sensor full-frame (3:2). With the projection scale $s = H f / h$, the vertical angle of view fills the canvas height and the horizontal field is narrower than the lens's horizontal angle, as derived in the [view design](view.md). Canvas pixels are square, so unlike the terminal no aspect correction is applied.

## Design decisions

### Rendering every frame from scratch

Each callback rebuilds the scene, the draw list and the whole canvas. Nothing is cached, which keeps the program a pure function of the timestamp and the selection, and costs nothing that matters at 640 × 480.

### Selection through a `Ref`

The `change` handler only writes the selected scene into a `Ref`; the animation loop reads it on the next frame. Rendering happens in one place, and switching scenes needs no coordination with the loop.

## Correctness and invariants

- The canvas bitmap is 640 × 480 and matches the projection's viewport.
- The picture at time $\tau$ depends only on $\tau$ and the current selection.

## Alternatives rejected

- **Separate pages per scene** would duplicate the set-up code.
- **A fixed frame counter** instead of the timestamp would make the speed depend on the refresh rate.

## Boundaries

`demo_canvas` does not export an API, run outside a browser, offer playback controls (see [demo_gsap](demo_gsap.md)), or adapt to the window size.
