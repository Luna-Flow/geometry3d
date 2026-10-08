# demo_gsap API

## Purpose

`Luna-Flow/geometry3d/demo_gsap` is a browser executable for the `js` target. It exports no MoonBit items; its interface is the HTML page it expects and the player it builds with the [GSAP SVG backend](backend/gsap.md).

## Build and serve

```sh
just gsap-build   # moon build src/demo_gsap --target js, then copy files
just gsap-serve   # build, then serve target/gsap-demo on http://localhost:8081
```

`gsap-build` copies `src/demo_gsap/index.html` and the compiled `demo_gsap.js` (as `demo.js`) into `target/gsap-demo/`. The page loads GSAP 3.13.0 from jsDelivr, sets `globalThis.gsap`, and then imports `demo.js`.

## Page contract

### `geometry3d-svg`

The `<svg id="geometry3d-svg">` element receives the rendered polygons, 640 × 480.

### `play-toggle`, `reverse`, `restart`

These buttons pause or resume, reverse, and restart the timeline. The program sets the text of `play-toggle` to `PLAY` or `PAUSE`.

### `progress`, `time-readout`

The range input `progress` (0 to 1) shows and seeks the timeline position; the element `time-readout` shows the time as `t / 8.00s`.

### `demo-select`

The selector chooses the scene: the value `dolly` selects the dolly zoom, any other value the torus.

### `speed`, `loop`

The `speed` selector sets the playback speed factor, and the `loop` checkbox switches between endless repetition and a single run.

The program aborts at start-up if one of these elements is missing.

## Timeline

The timeline is 8 seconds long and repeats forever by default. Every update renders the selected scene for the current time $t$.

### Torus

The torus scene turns the torus of the Canvas demo by $1.8\,t$ radians about $y$ (with $0.7$ and $0.25$ of that about $x$ and $z$), from 6.2 units away with a 35 mm lens.

### Dolly zoom

The dolly scene uses the camera distance $d(t) = 3.2 + 66.37 \cdot \tfrac12\big(1 + \sin(\pi t / 2)\big)$, so it completes two dolly cycles per 8-second loop. The focal length is $23 \cdot d / 3.2$ mm, and the cube turns at $1.23$, $1.71$ and $0.69$ rad/s.
