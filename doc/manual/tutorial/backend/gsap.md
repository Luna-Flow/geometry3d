# GSAP SVG Backend Tutorial

```sh
just gsap-serve
```

Open `http://localhost:8081`. The demo loads pinned GSAP ESM, assigns it to
`globalThis.gsap`, and then loads the MoonBit output.

Pass an SVG element and frontend `DrawList` to `render_draw_list`. For animation,
create `GsapPlayer` and rebuild the scene from the seconds supplied to its frame
callback. Call `kill` when the owning page or component is disposed.
