# demo_canvas API

## Purpose

`Luna-Flow/geometry3d/demo_canvas` is a browser executable for the `js` target. It exports no MoonBit items; its interface is the HTML page it expects and the scenes it draws with the [Canvas backend](backend/canvas.md).

## Build and serve

```sh
just canvas-build   # moon build src/demo_canvas --target js, then copy files
just canvas-serve   # build, then serve target/canvas-demo on http://localhost:8080
```

`canvas-build` copies `src/demo_canvas/index.html` and the compiled `demo_canvas.js` (as `demo.js`) into `target/canvas-demo/`.

## Page contract

### `geometry3d-canvas`

The page must contain a `<canvas id="geometry3d-canvas">`. The program sets its `width` and `height` attributes to 640 × 480 and draws into its 2D context. The program aborts at start-up if the element or the context is missing.

### `demo-select`

The page must contain a `<select id="demo-select">`. Its value `dolly` selects the dolly-zoom scene; any other value selects the torus. The program reads the value at start-up and on every `change` event.

## Scenes

### Torus

The torus scene shows a torus with radii 1.7 and 0.58 (32 × 18 segments), turning by $0.0006$ rad per millisecond of the animation timestamp about $x$, $y$ and $z$ in the ratio $0.7 : 1 : 0.25$. The camera is 6.2 units away with a 35 mm lens on a full-frame sensor.

### Dolly zoom

The dolly scene is the scene of the terminal demo's `--dolly` mode, with the frame number derived from the animation timestamp at 30 frames per second.
