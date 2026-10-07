# Core Design

## Responsibilities

- Represent small 3D meshes using vectors from `Luna-Flow/linear-algebra`.
- Keep transforms, normals, visibility, and projection-adjacent math backend neutral.
- Preserve face topology while applying transforms to vertex data.

## Invariants

- Geometry core must not depend on `Char`, ANSI output, terminal dimensions, or background patterns.
- Mesh factories return vertices centered around the origin.
- Quad faces are the canonical mesh topology; triangulation is a helper for raster backends.
- Closed primitive faces use outward-facing vertex winding so normal-based culling remains valid.

## Limitations

- No scene graph, materials, textures, clipping, camera orientation, asset loading, physics, or BVH.
- Sphere caps are represented as degenerate quads so the current quad pipeline can remain simple.

## Extension Points

- Extend `Transform3` deliberately while preserving point/direction semantics.
- Add alternate mesh factories while keeping the same `Mesh` topology contract.
- Add non-TUI backends by consuming `Mesh`, `Transform3`, and projected vertices without changing core.
