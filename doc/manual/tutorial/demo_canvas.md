# demo_canvas tutorial

This tutorial shows you how to build and open the browser Canvas demo, and how its program is put together so that you can adapt it.

## Quick start

From the repository root:

```sh
just canvas-serve
```

Open <http://localhost:8080>. The page shows a turning torus; choose "Dolly zoom" in the selector to switch to the dolly-zoom scene. Without `just`, run `moon build src/demo_canvas --target js`, copy `src/demo_canvas/index.html` and `_build/js/debug/build/demo_canvas/demo_canvas.js` (renamed to `demo.js`) into one directory, and serve it with any static file server; browsers do not load JavaScript modules from `file://` pages.

## Everyday tasks

### Read the program

`src/demo_canvas/main.mbt` has three parts:

1. Scene functions, `torus_scene(timestamp)` and `dolly_scene(frame)`, which build a `@frontend.Scene` for a moment in time, and matching `RenderView` functions using a `ScientificCamera`.
2. `render_frame(context, timestamp, selected)`, which picks the scene and calls `@canvas.render_scene`.
3. `main`, which looks up the canvas and the selector, stores the selection in a `Ref`, and starts a `requestAnimationFrame` loop that renders every frame.

### Add a scene

Add a constructor to the `DemoKind` enum, an `<option>` with a new value to `index.html`, a branch in `demo_kind` that maps the value to it, and a branch in `render_frame` that builds its scene and view. Rebuild with `just canvas-build`.

### Change the canvas size

The constants `WIDTH` and `HEIGHT` set both the viewport of the projection and the backend configuration; change them together with the attributes in `index.html`.

## Going further

The [Canvas tutorial](backend/canvas.md) explains the backend calls in isolation, and the [demo design](../design/demo.md) derives the dolly zoom shared with the terminal demo.

## Common pitfalls

- **Opening the file directly.** Serve the directory over HTTP; module scripts do not load from `file://`.
- **Stale build.** `just canvas-serve` rebuilds; a server started by hand serves whatever was copied last.

## Next steps

- The [demo_canvas API](../api/demo_canvas.md) states the page contract.
- The [demo_canvas design](../design/demo_canvas.md) explains how time is mapped onto the scenes.
- Try the vector version in [demo_gsap](demo_gsap.md).
