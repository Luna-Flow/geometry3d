# core tutorial

This tutorial teaches you to build meshes, place them in the world with transforms, and ask the questions every renderer asks about a face: where it is, which way it points, whether the eye can see it and how brightly it is lit. You need no camera or screen for any of it; those come in the [view tutorial](view.md).

| I want to | Use |
| --- | --- |
| build a cube, sphere or torus | `@core.cube_mesh`, `@core.sphere_mesh`, `@core.torus_mesh` |
| place an object in the world | `Transform3::scale(...).compose(Transform3::rotation(...)).compose(Transform3::translation(...))` |
| move a point or a direction | `t.apply_point(p)`, `t.apply_direction(d)` |
| find the faces the eye can see | `@core.face_is_visible(vertices, face, eye)` |
| shade a face | `@core.face_intensity(vertices, face, light)` |
| split quads for a rasterizer | `@core.triangulate_quad(face)` |

## Quick start

Add the module and `linear-algebra`, whose vector type `core` uses:

```sh
moon add Luna-Flow/geometry3d@0.5.1
moon add Luna-Flow/linear-algebra@0.4.2
```

Import the package in your `moon.pkg`:

```moonbit nocheck
import {
  "moonbitlang/core/math",
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

Then turn a cube by 45° about the vertical axis and count the faces an eye in front of it can see:

```moonbit
fn main {
  let cube = @core.cube_mesh(1.0)
  let turn = @core.Transform3::rotation(0.0, @math.PI / 4.0, 0.0)
  let turned = turn.apply_mesh(cube)
  let eye = @core.vec3(0.0, 0.0, -4.5)
  let mut visible = 0
  for face in turned.faces {
    if @core.face_is_visible(turned.vertices, face, eye) {
      visible += 1
    }
  }
  println("faces: \{turned.faces.length()}, visible: \{visible}")
}
```

Output:

```text
faces: 6, visible: 2
```

Turned by 45°, the cube shows the eye one corner edge and the two faces that meet at it.

## Everyday tasks

### Build primitive meshes

Each generator returns a closed mesh centred on the origin. Resolution arguments below 3 are raised to 3.

```moonbit
test "primitive meshes" {
  let sphere = @core.sphere_mesh(1.0, 8, 12)
  inspect(sphere.vertices.length(), content="86")
  inspect(sphere.faces.length(), content="96")
  let cylinder = @core.cylinder_mesh(0.5, 2.0, 16)
  inspect(cylinder.faces.length(), content="48")
  let pyramid = @core.triangular_pyramid_mesh(1.0, 1.5)
  inspect(pyramid.vertices.length(), content="4")
  let torus = @core.torus_mesh(2.0, 0.5, 24, 12)
  inspect(torus.vertices.length(), content="288")
}
```

A UV sphere with `rings` rings and `segments` segments has two pole vertices plus `rings - 1` latitude circles, and `rings * segments` faces; the faces at the poles are triangles stored as quads whose last index repeats the first.

### Place an object in the world

A model transform usually scales, then rotates, then translates. `compose` takes the next step as its argument, so the chain reads in that order:

```moonbit
test "model transform" {
  let model = @core.Transform3::scale(2.0, 1.0, 1.0)
    .compose(@core.Transform3::rotation(0.0, 0.0, @math.PI / 2.0))
    .compose(@core.Transform3::translation(0.0, 0.0, 5.0))
  // (1, 0, 0) -> scale -> (2, 0, 0) -> rotate -> (0, 2, 0) -> move -> (0, 2, 5)
  let p = model.apply_point(@core.vec3(1.0, 0.0, 0.0))
  inspect(p[0].abs() < 1.0e-12, content="true")
  inspect(p[1], content="2")
  inspect(p[2], content="5")
  // the same transform applied to a whole mesh keeps its faces
  let box = model.apply_mesh(@core.cube_mesh(0.5))
  inspect(box.faces.length(), content="6")
}
```

### Tell points from directions

A direction, such as a light ray or a velocity, must not move when the object is translated. Use `apply_direction` for it:

```moonbit
test "points and directions" {
  let t = @core.Transform3::translation(10.0, 0.0, 0.0)
  let up = @core.vec3(0.0, 1.0, 0.0)
  inspect(t.apply_point(up)[0], content="10")
  inspect(t.apply_direction(up)[0], content="0")
  inspect(t.apply_direction(up)[1], content="1")
}
```

### Shade the visible faces

`face_normal` gives the outward unit normal, `face_is_visible` the back-face test, and `face_intensity` the Lambert term for a light direction. The light direction points from the surface towards the light and must be a unit vector:

```moonbit
fn shade_report(mesh : @core.Mesh, eye : @la.Vector[Double]) -> Array[String] {
  let light = @core.normalize_vec(@core.vec3(0.0, 1.0, -1.0))
  let lines = []
  for face in mesh.faces {
    if @core.face_is_visible(mesh.vertices, face, eye) {
      let n = @core.face_normal(mesh.vertices, face)
      let i = @core.face_intensity(mesh.vertices, face, light)
      let pct = (i * 100.0).round().to_int()
      lines.push("normal (\{n[0]}, \{n[1]}, \{n[2]}) intensity \{pct}%")
    }
  }
  lines
}

test "shade the visible faces" {
  let cube = @core.cube_mesh(1.0)
  let eye = @core.vec3(0.0, 3.0, -4.0)
  inspect(
    shade_report(cube, eye).join("\n"),
    content=(
      #|normal (0, 0, -1) intensity 71%
      #|normal (0, 1, 0) intensity 71%
    ),
  )
}
```

The eye above the cube and in front of it sees the front and the top face; a light from the same quadrant lights both at $\cos 45° \approx 71\%$.

### Triangulate for a rasterizer

Rasterizers draw triangles. `triangulate_quad` splits a quad into a fan that keeps its winding:

```moonbit
test "triangulate" {
  let pyramid = @core.triangular_pyramid_mesh(1.0, 1.0)
  let mut triangles = 0
  for face in pyramid.faces {
    for t in @core.triangulate_quad(face) {
      // the second triangle of a degenerate quad repeats a vertex
      if t.a != t.b && t.b != t.c && t.c != t.a {
        triangles += 1
      }
    }
  }
  inspect(triangles, content="4")
}
```

## Going further

### Bring your own matrix

`Transform3::from_matrix` accepts any 4×4 `@la.Matrix[Double]`, including matrices built with `linear-algebra` operations and projective matrices. `apply_point` performs the homogeneous division, so a matrix whose last row copies $z$ into $w$ divides by depth:

```moonbit
test "projective matrix" {
  let divide_by_z = @la.Matrix::from_2d_array([
    [1.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 0.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
    [0.0, 0.0, 1.0, 0.0],
  ])
  let p = @core.Transform3::from_matrix(divide_by_z).apply_point(
    @core.vec3(2.0, 4.0, 2.0),
  )
  inspect(p[0], content="1")
  inspect(p[1], content="2")
  // composing with the matrix product of linear-algebra
  let twice = @core.Transform3::from_matrix(
    @core.rotation_z(0.25) * @core.rotation_z(0.25),
  )
  let q = twice.apply_point(@core.vec3(1.0, 0.0, 0.0))
  inspect((q[0] - @math.cos(0.5)).abs() < 1.0e-12, content="true")
}
```

### Hand the result to the rest of the pipeline

`core` stops at world space. The `frontend` package takes a `Mesh` and a `Transform3` per object in a `SceneObject`, and does the camera transform, projection, culling and shading for you; see the [frontend tutorial](frontend.md).

### Performance

Every vector operation allocates a new `@la.Vector[Double]`, and `apply_mesh` allocates one per vertex. That is fine for the few thousand vertices of the demos. For large meshes, transform once per frame and reuse the result rather than calling `apply_point` repeatedly on the same vertices.

## Common pitfalls

- **Composition order.** `a.compose(b)` applies `a` first. The matrix is `b.matrix * a.matrix`, which looks reversed if you think in matrix products.
- **Two different lengths.** `@core.vec_length(v)` is the Euclidean norm; `v.length()` from `linear-algebra` is the number of components.
- **Radians.** All angles are in radians. `rotation_matrix(α, β, γ)` applies $x$, then $y$, then $z$ about world axes, and loses a degree of freedom at $\beta = \pm 90°$ (gimbal lock).
- **Light direction.** `face_intensity` expects the unit vector from the surface towards the light. A vector pointing the other way lights the back of the object; an unnormalized vector gives intensities above 1.
- **Mirror transforms.** A scale with an odd number of negative factors turns faces inside out: their normals point inwards, and the back-face test hides the wrong side.
- **Inward cylinders, cones and pyramids.** `cylinder_mesh`, `cone_mesh` and `triangular_pyramid_mesh` currently wind their faces inwards, so they render inside out. Mirror them once with `Transform3::scale(1.0, 1.0, -1.0)` (cylinder, cone) or `Transform3::scale(-1.0, 1.0, 1.0)` (pyramid) before use; see the [core API](../api/core.md#cube_mesh-sphere_mesh-cylinder_mesh-cone_mesh-triangular_pyramid_mesh-torus_mesh).
- **Building meshes by hand.** The fields of `Mesh` and `QuadFace` are read-only outside `core`, so a record literal such as `{ vertices, faces }` does not compile in your package. Start from a generator and reshape it with transforms.
- **Absolute tolerance.** `DEPTH_EPSILON` is $10^{-9}$ in world units. Scenes far larger or smaller than unit scale may hit it unexpectedly.

## Next steps

- The [core API](../api/core.md) lists every function with its exact signature.
- The [core design](../design/core.md) derives homogeneous transforms, the Euler-angle matrix, face orientation and Lambert shading.
- Continue with the [view tutorial](view.md) to put a camera in front of your meshes.
- `Luna-Flow/linear-algebra` documents the vector and matrix types: <https://lunaflow.cn/en/linear-algebra/>.
