# Core Tutorial

## Build A Mesh

```moonbit
let cube = cube_mesh(1.0)
let sphere = sphere_mesh(2.4, 18, 36)
let torus = torus_mesh(2.1, 0.72, 28, 16)
```

Both meshes use `@la.Vector[Double]` vertices and `QuadFace` topology.

## Transform A Mesh

```moonbit
let transform = Transform3::rotation(0.2, 0.4, 0.0)
let transformed = transform.apply_mesh(cube)
```

`Transform3` also provides translation, non-uniform scale, and composition.

The transform layer uses `Luna-Flow/linear-algebra` matrix construction,
matrix multiplication, and `mul_vec`.

## Inspect Face Geometry

```moonbit
let face = transformed.faces[0]
let normal = face_normal(transformed.vertices, face)
let center = face_center(transformed.vertices, face)
let visible = face_is_visible(transformed.vertices, face, vec3(0.0, 0.0, -4.5))
```

Use these helpers before projection or rendering. They are independent of any
screen size or backend.
