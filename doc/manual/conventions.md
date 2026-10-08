# Repository conventions

These rules add to the Luna-Flow documentation standard for `geometry3d`.

## Scope

- Document the version on the current branch, as described by each package's `pkg.generated.mbti`. The JavaScript-only packages (`backend/canvas`, `backend/gsap`, `demo_canvas`, `demo_gsap`) have no committed interface file; their public surface is the one `moon info --target js` reports.
- Do not document speculative engine features such as scene graphs, materials, textures, physics, BVH, or asset loaders unless they are implemented.

## Package boundaries

- Keep geometry core documentation free of terminal, ANSI, and TUI concerns.
- Keep terminal y-scale, background patterns, and character rasterization under `backend/tui` or `demo`.
- Keep browser DOM, Canvas, scanline, and JS-target details under `backend/canvas`, `backend/gsap`, `demo_canvas` or `demo_gsap`.
- When behavior crosses package boundaries, update the API, design, and tutorial pages of every affected package together.

## Executables

The demo packages export no MoonBit items. Their API page documents the command line (`demo`) or the HTML page contract (`demo_canvas`, `demo_gsap`) instead.

## Examples

Every `moonbit` block that is not marked `nocheck` must compile against the current code, and the outputs shown in `inspect` snapshots and `text` blocks must be the real outputs. Check them by copying the blocks into a scratch module that depends on this repository and running `moon test` (with `--target js` for the browser pages).
