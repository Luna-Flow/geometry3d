# demo_gsap tutorial

This tutorial shows you how to run the GSAP SVG demo and how its program connects page controls to a `GsapPlayer`.

| I want to | Use |
| --- | --- |
| run the player | `just gsap-serve` |
| change the animation length | the constant `DURATION_SECONDS` |
| use a local copy of GSAP | a local `gsap` module in `index.html` that sets `globalThis.gsap` |

## Quick start

From the repository root:

```sh
just gsap-serve
```

Open <http://localhost:8081>. The torus turns in an SVG drawing; use the buttons to pause, reverse and restart, drag the progress bar to seek, pick a speed, untick "LOOP" to stop at the end, and choose "Dolly zoom" to switch scenes. The page needs network access to load GSAP from jsDelivr.

## Everyday tasks

### Read the program

`src/demo_gsap/main.mbt` builds the scenes like the Canvas demo, but as functions of time in seconds. `main` creates one `@gsap.GsapPlayer` of 8 seconds whose callback renders the selected scene and updates the progress display. It then binds every control to one player method: `play`/`pause`, `reverse`, `restart`, `set_progress`, `set_time_scale` and `set_repeat`. Three small `extern "js"` functions handle the page details that `rabbita` does not cover: reading control values and writing the readout and the button label.

### Change the duration

`DURATION_SECONDS` sets the timeline length and the readout. The torus angle is proportional to time, so a loop is seamless only if the torus completes whole turns in the new duration; the dolly scene repeats every 4 seconds.

### Use a local copy of GSAP

Replace the jsDelivr URL in `index.html` with the path of a local `gsap` ES module; the program only needs `globalThis.gsap` to be set before `demo.js` is imported.

## Going further

The [GSAP tutorial](backend/gsap.md) shows the player and the renderer on their own, and the [GSAP design](../design/backend/gsap.md) explains when painter's ordering is exact. Compare the torus here with the [Canvas demo](demo_canvas.md): where the torus overlaps itself, the SVG version can briefly draw a far triangle over a near one.

## Common pitfalls

- **Offline use.** Without network access GSAP does not load and the program stops with "geometry3d GSAP backend requires globalThis.gsap".
- **Opening the file directly.** Serve the directory over HTTP; module scripts do not load from `file://`.

## Next steps

- The [demo_gsap API](../api/demo_gsap.md) states the page contract.
- The [demo_gsap design](../design/demo_gsap.md) explains how time drives the scenes.
