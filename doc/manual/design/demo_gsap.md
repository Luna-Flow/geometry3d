# demo_gsap design

## Design goal

`demo_gsap` shows that a `geometry3d` scene can be scrubbed, reversed and replayed like any GSAP animation, because each picture is a pure function of time. It is a complete player page with the smallest possible amount of JavaScript.

## Mathematical background

### Scenes as functions of time

GSAP reports the timeline time $t \in [0, 8]$ seconds and the program draws $\text{render}(\text{scene}(t))$. Nothing depends on the previous frame, so seeking to any $t$, playing backwards or at another speed shows exactly the picture for that $t$.

The dolly distance $d(t) = 3.2 + 66.37 \cdot \tfrac12\big(1 + \sin(\pi t/2)\big)$ has period 4 s, so the 8-second loop contains two full cycles and joins seamlessly at $t = 8$. The focal length follows $f = 23\, d / 3.2$ mm, which keeps the cube's projected size constant as derived in the [demo design](demo.md). The torus angle $1.8\,t$ advances $14.4$ rad per loop, which is not a whole number of turns ($2\pi \cdot 2.29$), so the torus jumps slightly when the loop restarts.

## Design decisions

### GSAP owns the clock

All playback state (paused, direction, speed, repeat, position) lives in the GSAP timeline, and the controls call `GsapPlayer` methods directly. The MoonBit program keeps only the selected scene. Changing the scene re-renders the current time immediately, so a paused player updates too.

### Thin JavaScript glue

Reading `event.target.value`, setting a range input and writing text are done in three `extern "js"` functions. They are page-specific and would not be reused, so they are not part of the backend.

## Correctness and invariants

- The picture shown for timeline time $t$ is independent of how the playhead reached $t$.
- The dolly scene is periodic in the loop; the torus scene is not (see above).

## Alternatives rejected

- **Keeping a frame counter in MoonBit** would break seeking and reversing.
- **Building the controls from MoonBit** with `rabbita` would add code without changing behaviour; the static HTML is simpler.

## Boundaries

`demo_gsap` does not export an API, work offline as shipped, or resolve the painter's-ordering artefacts of the backend (see the [GSAP design](backend/gsap.md)).
