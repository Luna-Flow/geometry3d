# Demo Design

## Responsibilities

- Wire the core and TUI renderer together.
- Keep CLI behavior small and predictable.
- Demonstrate the linear algebra pipeline without adding engine-level concepts.

## Defaults

- Cube: rotating, radius/half-size `1.0`.
- Sphere: static, radius `2.4`, `18` rings, `36` segments.
- Hitchcock: central cube plus background cylinder, cone, triangular pyramid, and rotated variants.
- Renderer: `80x32`, dotted background, projection scale `24.0`, terminal y-scale `0.5`.

## Non-Goals

- Runtime UI, command parser, config files, or interactive controls.
- Persisted scenes or asset loading.
- Snapshot-stable ASCII art tests.
