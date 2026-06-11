# Demo Design

## Responsibilities

- Wire the core and TUI renderer together.
- Keep CLI behavior small and predictable.
- Demonstrate the linear algebra pipeline without adding engine-level concepts.

## Defaults

- Cube: rotating, radius/half-size `1.0`.
- Sphere: static, radius `2.4`, `18` rings, `36` segments.
- Torus: rotating, major radius `2.1`, minor radius `0.72`, outward face winding.
- Hitchcock: central cube plus background cylinder, cone, triangular pyramid, and rotated variants.
- Renderer: terminal-derived viewport with `80x32` fallback, dotted background,
  scientific-camera projection, and terminal y-scale `0.5`.

## Non-Goals

- Runtime UI, command parser, config files, or interactive controls.
- Persisted scenes or asset loading.
- Snapshot-stable ASCII art tests.
