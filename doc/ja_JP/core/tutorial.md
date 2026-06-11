# Core Tutorial

## Mesh を作る

```moonbit
let cube = cube_mesh(1.0)
let sphere = sphere_mesh(2.4, 18, 36)
let torus = torus_mesh(2.1, 0.72, 28, 16)
```

`Transform3` は translation、non-uniform scale、compose も提供します。

どちらも `@la.Vector[Double]` vertices と `QuadFace` topology を使います。

## Mesh を変換する

```moonbit
let transform = Transform3::rotation(0.2, 0.4, 0.0)
let transformed = transform.apply_mesh(cube)
```

transform layer は `Luna-Flow/linear-algebra` の matrix construction、
matrix multiplication、`mul_vec` を使います。

## Face Geometry を見る

```moonbit
let face = transformed.faces[0]
let normal = face_normal(transformed.vertices, face)
let center = face_center(transformed.vertices, face)
let visible = face_is_visible(transformed.vertices, face, vec3(0.0, 0.0, -4.5))
```

これらの helper は projection や rendering の前に使います。screen size や backend
には依存しません。
