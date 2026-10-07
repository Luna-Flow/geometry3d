# Canvas Backend Tutorial

Build and serve the browser demo:

```sh
just canvas-serve
```

Open `http://localhost:8080` and use the selector to switch between Torus and
Dolly zoom. The build output is written to `target/canvas-demo`.

For application code, obtain a `CanvasRenderingContext2D` with
`moonbit-community/rabbita/dom`, build a frontend draw list, and call
`render_draw_list`. Use `render_scene` when the backend should build the draw
list from a `Scene` and `RenderView`.
