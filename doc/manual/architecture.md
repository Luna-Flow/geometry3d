# Architecture

This guide follows one frame through the packages of `geometry3d` and explains where each responsibility lives and why. The package pages hold the details and the derivations.

## Layers

```text
Luna-Flow/linear-algebra  (Vector[Double], Matrix[Double])
        │
      core        meshes, transforms, normals, visibility, Lambert
        │
      view        camera, projection, perspective-correct depth, lens model
        │
    frontend      scene → DrawList; shadow map; LumaBuffer; exposure; flow; timelines
        │
   ┌────┼──────────────┐
backend/tui   backend/canvas   backend/gsap
   │              │                │
  demo       demo_canvas       demo_gsap
```

Each package imports only packages above it. `core`, `view` and `frontend` know nothing about characters, colours, the DOM or the operating system; each backend knows nothing about the others; and the demos are the only code that touches the clock, the environment, files or page elements.

## One frame

1. **Model.** `frontend` applies each `SceneObject`'s `Transform3` to its mesh (`core`), giving world-space vertices.
2. **Shadows.** It renders the world-space scene from the directional light into a 128 × 128 orthographic depth map.
3. **View.** It maps vertices into camera space with the `Camera3` view transform (`view`): $x$ right, $y$ up, $z$ forward.
4. **Projection.** It projects them with `PerspectiveProjection` into the viewport: $x_s = W/2 + s x/z$, $y_s = H/2 - s y/z$, keeping $z$ as depth.
5. **Culling and shading.** For every face that faces the eye it computes the Lambert term, attenuates it by the fraction of the face that the shadow map says is lit, and emits two `DrawTriangle`s with that intensity.
6. **Backend.** A backend turns the `DrawList` into output:
   - `backend/tui` squeezes $y$ by `terminal_y_scale`, picks a ramp character per triangle and rasterizes with a depth buffer into a `FrameBuffer`;
   - `backend/canvas` rasterizes into the frontend `LumaBuffer` and paints runs of equal shade on a canvas;
   - `backend/gsap` sorts the triangles far to near and writes SVG polygons.
7. **Presentation.** A demo prints the frame, paints it in the browser, or stores it in a `.tui3d` sequence.

## Why the boundary is the draw list

All three backends need the same thing: where each triangle is on the screen, how far away it is, and how bright it is. Everything before that point is device-independent geometry and is computed once in the frontend; everything after it is a device decision. The [frontend design](design/frontend.md) discusses the alternatives.

Occlusion is the one decision that differs between backends. The TUI and Canvas backends use the same depth-buffer rule and are exact. SVG has no depth buffer, so the GSAP backend uses painter's ordering, which is exact for single convex objects and approximate otherwise ([GSAP design](design/backend/gsap.md)).

## Conventions that cross packages

- **Coordinates.** World and camera space follow the left-handed convention of Direct3D: with the default camera, $+x$ is right, $+y$ up and $+z$ away from the viewer. Screen $y$ grows downwards. Faces are wound so that $(b - a) \times (c - a)$ points outwards.
- **Light direction.** A `Light` stores the unit vector from the scene towards the light.
- **Depth.** Depth is camera-space $z$ everywhere after projection; smaller is nearer. Empty pixels have depth $10^{30}$.
- **Tolerance.** `@core.DEPTH_EPSILON` = $10^{-9}$ decides degenerate normals, homogeneous division, zero-area triangles and depth-test ties in every package.
- **Lenient constructors.** Constructors replace invalid sizes and counts by defaults instead of failing; nothing in the library returns `Result` or raises.
- **Read-only records.** Public structs are `pub struct`: callers can read every field but build values only through constructors.

## Not in this repository

There is no clipping against a near plane, no scene graph, no materials or textures, no smooth shading, no asset loading, no physics and no spatial index. The [repository conventions](conventions.md) ask documentation not to describe such features until they exist.
