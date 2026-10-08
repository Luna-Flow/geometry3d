# core API

The package `Luna-Flow/geometry3d/core` holds the 3D data and the affine math of the pipeline: vectors, quad meshes, mesh generators, face normals, back-face visibility, Lambert intensity and 4×4 homogeneous transforms. It knows nothing about cameras, screens, terminals or the browser. Vectors and matrices are the mutable dense types of `Luna-Flow/linear-algebra`, imported here as `@la`.

Import it with:

```moonbit nocheck
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

The [core design](../design/core.md) derives the formulas used below, and the [core tutorial](../tutorial/core.md) walks through them with examples.

## Constants

### `DEPTH_EPSILON`

`DEPTH_EPSILON` is the shared tolerance of the whole pipeline.

```mbti
pub const DEPTH_EPSILON : Double = 1.0e-9
```

It is used as the length below which `normalize_vec` returns the zero vector, the size of `w` below which `Transform3::apply_point` skips the homogeneous division, the minimum triangle area for rasterization, and the margin of every depth test in the `view`, `frontend` and backend packages.

## Vectors

All vector helpers take and return `@la.Vector[Double]`. They read only the components they need (indices `0..2` for 3D helpers), so a 4-component vector passed to a 3D helper is treated as its first three components.

### `vec3`

`vec3` builds the 3-component vector $(x, y, z)$.

```mbti
pub fn vec3(Double, Double, Double) -> @mutable.Vector[Double]
```

### `vec4`

`vec4` builds the 4-component vector $(x, y, z, w)$, the homogeneous form used inside `Transform3`.

```mbti
pub fn vec4(Double, Double, Double, Double) -> @mutable.Vector[Double]
```

### `sub_vec`

`sub_vec(a, b)` returns the 3D difference $a - b$.

```mbti
pub fn sub_vec(@mutable.Vector[Double], @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

### `cross_vec`

`cross_vec(a, b)` returns the cross product $a \times b = (a_y b_z - a_z b_y,\ a_z b_x - a_x b_z,\ a_x b_y - a_y b_x)$.

```mbti
pub fn cross_vec(@mutable.Vector[Double], @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

### `vec_length`

`vec_length(v)` returns the Euclidean norm $\lVert v \rVert = \sqrt{v \cdot v}$ over all components of `v`.

```mbti
pub fn vec_length(@mutable.Vector[Double]) -> Double
```

Do not confuse it with `@la.Vector::length`, which returns the number of components.

### `normalize_vec`

`normalize_vec(v)` returns $v / \lVert v \rVert$, or the zero vector $(0, 0, 0)$ when $\lVert v \rVert \le$ `DEPTH_EPSILON`.

```mbti
pub fn normalize_vec(@mutable.Vector[Double]) -> @mutable.Vector[Double]
```

The zero result makes degenerate faces harmless: their normal is zero, so they are never visible and never lit.

```moonbit
test "vector helpers" {
  let x = @core.vec3(1.0, 0.0, 0.0)
  let y = @core.vec3(0.0, 1.0, 0.0)
  let z = @core.cross_vec(x, y)
  inspect(z[2], content="1")
  inspect(@core.vec_length(@core.vec3(3.0, 4.0, 0.0)), content="5")
  let n = @core.normalize_vec(@core.vec3(0.0, 0.0, 1.0e-12))
  inspect(@core.vec_length(n), content="0")
  inspect(@core.sub_vec(z, x)[0], content="-1")
}
```

### `min3`, `max3`

`min3` and `max3` return the smallest and largest of three numbers. The rasterizers use them for triangle bounding boxes.

```mbti
pub fn min3(Double, Double, Double) -> Double
pub fn max3(Double, Double, Double) -> Double
```

```moonbit
test "min3 and max3" {
  inspect(@core.min3(2.0, -1.0, 0.5), content="-1")
  inspect(@core.max3(2.0, -1.0, 0.5), content="2")
}
```

## Meshes

### `QuadFace`

`QuadFace` is one face of a mesh, given by four indices into the vertex array.

```mbti
pub struct QuadFace {
  a : Int
  b : Int
  c : Int
  d : Int
}
```

The vertices are listed so that $(b - a) \times (c - a)$ points out of a closed mesh. A triangle is stored as a degenerate quad whose last index repeats the first ($d = a$).

### `TriangleFace`

`TriangleFace` is a triangle given by three vertex indices; `triangulate_quad` produces it for the rasterizers.

```mbti
pub struct TriangleFace {
  a : Int
  b : Int
  c : Int
}
```

### `Mesh`

`Mesh` is an indexed face set: vertex positions plus quad faces that refer to them.

```mbti
pub struct Mesh {
  vertices : Array[@mutable.Vector[Double]]
  faces : Array[QuadFace]
}
```

The fields of `Mesh`, `QuadFace` and `TriangleFace` are read-only outside the package, so you obtain meshes from the generators below and change them with `Transform3::apply_mesh`.

### `cube_mesh`, `sphere_mesh`, `cylinder_mesh`, `cone_mesh`, `triangular_pyramid_mesh`, `torus_mesh`

These generators build the closed primitive meshes.

Every generator returns a mesh centred on the origin, with outward winding, and clamps its resolution arguments to at least 3.

| Generator | Shape | Vertices | Faces |
| --- | --- | --- | --- |
| `cube_mesh(s)` | cube $[-s, s]^3$ | 8 | 6 |
| `sphere_mesh(r, rings, segments)` | UV sphere of radius $r$, poles on the $y$ axis | $2 + (\mathit{rings} - 1)\,\mathit{segments}$ | $\mathit{rings} \cdot \mathit{segments}$ |
| `cylinder_mesh(r, h, n)` | capped cylinder along $y$, $y \in [-h/2, h/2]$ | $2n + 2$ | $3n$ |
| `cone_mesh(r, h, n)` | capped cone, apex at $y = h/2$, base at $y = -h/2$ | $n + 2$ | $2n$ |
| `triangular_pyramid_mesh(r, h)` | tetrahedron with a base triangle inscribed in a circle of radius $r$ | 4 | 4 |
| `torus_mesh(R, r, M, m)` | torus around the $y$ axis | $M m$ | $M m$ |

```mbti
pub fn cube_mesh(Double) -> Mesh
pub fn sphere_mesh(Double, Int, Int) -> Mesh
pub fn cylinder_mesh(Double, Double, Int) -> Mesh
pub fn cone_mesh(Double, Double, Int) -> Mesh
pub fn triangular_pyramid_mesh(Double, Double) -> Mesh
pub fn torus_mesh(Double, Double, Int, Int) -> Mesh
```

Caps, cone sides and pyramid faces are degenerate quads ($d = a$). `torus_mesh` also replaces a non-positive major radius by `1.0` and a non-positive minor radius by `0.25`; the other generators use their size arguments as given.

```moonbit
test "mesh generators" {
  let cube = @core.cube_mesh(1.0)
  inspect(cube.vertices.length(), content="8")
  inspect(cube.faces.length(), content="6")
  let sphere = @core.sphere_mesh(2.4, 18, 36)
  inspect(sphere.vertices.length(), content="614")
  inspect(sphere.faces.length(), content="648")
  let torus = @core.torus_mesh(2.1, 0.72, 28, 16)
  inspect(torus.faces.length(), content="448")
  inspect(@core.cone_mesh(1.0, 2.0, 2).faces.length(), content="6")
}
```

### `face_vertices`

`face_vertices(mesh, face)` returns the four vertices of `face`, in the order `a`, `b`, `c`, `d`.

```mbti
pub fn face_vertices(Mesh, QuadFace) -> Array[@mutable.Vector[Double]]
```

The vectors are shared with `mesh.vertices`, not copied.

### `triangulate_quad`

`triangulate_quad(face)` splits a quad into the fan $(a, b, c)$, $(a, c, d)$.

```mbti
pub fn triangulate_quad(QuadFace) -> Array[TriangleFace]
```

Both triangles keep the winding of the quad. For a degenerate quad the second triangle $(a, c, a)$ has zero area and the rasterizers skip it.

```moonbit
test "face vertices and triangulation" {
  let cube = @core.cube_mesh(1.0)
  let face = cube.faces[0]
  inspect(@core.face_vertices(cube, face).length(), content="4")
  let triangles = @core.triangulate_quad(face)
  inspect(triangles.length(), content="2")
  inspect(triangles[1].a == face.a && triangles[1].c == face.d, content="true")
}
```

## Faces

The face helpers take the vertex array separately from the face, so you can pass vertices that were already transformed into another space (for example camera space) while reusing the face list of the original mesh.

### `face_center`

`face_center(vertices, face)` returns the mean of the four face vertices, $\tfrac14(v_a + v_b + v_c + v_d)$.

```mbti
pub fn face_center(Array[@mutable.Vector[Double]], QuadFace) -> @mutable.Vector[Double]
```

For a degenerate quad the repeated vertex is counted twice.

### `face_normal`

`face_normal(vertices, face)` returns the unit normal $\hat n = \operatorname{normalize}((v_b - v_a) \times (v_c - v_a))$, computed from the first three vertices.

```mbti
pub fn face_normal(Array[@mutable.Vector[Double]], QuadFace) -> @mutable.Vector[Double]
```

It returns the zero vector when the three vertices are collinear.

### `face_is_visible`

`face_is_visible(vertices, face, eye)` is the back-face test: it returns `true` when $\hat n \cdot (e - c) > 0$, where $c$ is the face centre.

```mbti
pub fn face_is_visible(Array[@mutable.Vector[Double]], QuadFace, @mutable.Vector[Double]) -> Bool
```

### `face_intensity`

`face_intensity(vertices, face, light)` returns the Lambert term $\max(0, \hat n \cdot \ell)$.

```mbti
pub fn face_intensity(Array[@mutable.Vector[Double]], QuadFace, @mutable.Vector[Double]) -> Double
```

`light` should be a unit vector pointing from the surface towards the light; the result is then the cosine of the angle of incidence, in $[0, 1]$.

```moonbit
test "face helpers" {
  let cube = @core.cube_mesh(1.0)
  let front = cube.faces[0] // the face at z = -1
  let n = @core.face_normal(cube.vertices, front)
  inspect(n[2], content="-1")
  let c = @core.face_center(cube.vertices, front)
  inspect(c[2], content="-1")
  let eye = @core.vec3(0.0, 0.0, -4.5)
  inspect(@core.face_is_visible(cube.vertices, front, eye), content="true")
  inspect(@core.face_is_visible(cube.vertices, cube.faces[1], eye), content="false")
  let light = @core.vec3(0.0, 0.0, -1.0)
  inspect(@core.face_intensity(cube.vertices, front, light), content="1")
}
```

## Matrices

The matrix builders return 4×4 `@la.Matrix[Double]` values that act on column vectors $(x, y, z, w)^\mathsf{T}$. Angles are in radians.

### `identity_matrix4`

`identity_matrix4()` returns the 4×4 identity matrix $I_4$.

```mbti
pub fn identity_matrix4() -> @mutable.Matrix[Double]
```

### `translation_matrix`

`translation_matrix(x, y, z)` returns $\begin{pmatrix} I_3 & t \\ 0 & 1 \end{pmatrix}$ with $t = (x, y, z)^\mathsf{T}$.

```mbti
pub fn translation_matrix(Double, Double, Double) -> @mutable.Matrix[Double]
```

### `scale_matrix`

`scale_matrix(x, y, z)` returns $\operatorname{diag}(x, y, z, 1)$.

```mbti
pub fn scale_matrix(Double, Double, Double) -> @mutable.Matrix[Double]
```

### `rotation_x`, `rotation_y`, `rotation_z`

`rotation_x(θ)`, `rotation_y(θ)` and `rotation_z(θ)` return the rotations by $\theta$ about the coordinate axes.

```mbti
pub fn rotation_x(Double) -> @mutable.Matrix[Double]
pub fn rotation_y(Double) -> @mutable.Matrix[Double]
pub fn rotation_z(Double) -> @mutable.Matrix[Double]
```

Their 3×3 blocks are

$$
R_x(\theta) = \begin{pmatrix} 1 & 0 & 0 \\ 0 & \cos\theta & -\sin\theta \\ 0 & \sin\theta & \cos\theta \end{pmatrix},\quad
R_y(\theta) = \begin{pmatrix} \cos\theta & 0 & \sin\theta \\ 0 & 1 & 0 \\ -\sin\theta & 0 & \cos\theta \end{pmatrix},\quad
R_z(\theta) = \begin{pmatrix} \cos\theta & -\sin\theta & 0 \\ \sin\theta & \cos\theta & 0 \\ 0 & 0 & 1 \end{pmatrix}.
$$

A positive angle turns $y$ towards $z$, $z$ towards $x$, and $x$ towards $y$ respectively.

### `rotation_matrix`

`rotation_matrix(α, β, γ)` returns the Euler-angle rotation $R_z(\gamma)\,R_y(\beta)\,R_x(\alpha)$.

```mbti
pub fn rotation_matrix(Double, Double, Double) -> @mutable.Matrix[Double]
```

Applied to a column vector, the rotation about $x$ acts first, then $y$, then $z$, all about the fixed world axes. The [core design](../design/core.md) gives the full matrix and its gimbal-lock behaviour.

```moonbit
test "matrix builders" {
  let r = @core.rotation_z(@math.PI / 2.0)
  let p = r.unchecked_mul_vec(@core.vec4(1.0, 0.0, 0.0, 1.0))
  inspect(p[1], content="1")
  let t = @core.translation_matrix(1.0, 2.0, 3.0)
  let q = t.unchecked_mul_vec(@core.vec4(0.0, 0.0, 0.0, 1.0))
  inspect(q[2], content="3")
  let m = @core.rotation_matrix(0.0, 0.0, 0.0)
  inspect(m.get(0, 0) == 1.0 && m.get(0, 1) == 0.0, content="true")
}
```

## Transforms

### `Transform3`

`Transform3` wraps one 4×4 homogeneous matrix and applies it to points, directions and meshes.

```mbti
pub struct Transform3 {
  matrix : @mutable.Matrix[Double]
}
```

### `Transform3::identity`, `Transform3::translation`, `Transform3::scale`, `Transform3::rotation`

These constructors wrap `identity_matrix4`, `translation_matrix`, `scale_matrix` and `rotation_matrix`.

```mbti
pub fn Transform3::identity() -> Self
pub fn Transform3::translation(Double, Double, Double) -> Self
pub fn Transform3::scale(Double, Double, Double) -> Self
pub fn Transform3::rotation(Double, Double, Double) -> Self
```

### `Transform3::rotation_euler`

`Transform3::rotation_euler(α, β, γ)` is the same as `Transform3::rotation(α, β, γ)`; the name states the angle convention.

```mbti
pub fn Transform3::rotation_euler(Double, Double, Double) -> Self
```

### `Transform3::from_matrix`

`Transform3::from_matrix(m)` wraps any 4×4 matrix, including projective ones whose last row is not $(0, 0, 0, 1)$.

```mbti
pub fn Transform3::from_matrix(@mutable.Matrix[Double]) -> Self
```

The matrix is stored, not copied, and must be 4×4: the apply methods abort on other shapes.

### `Transform3::compose`

`t.compose(next)` returns the transform that applies `t` first and `next` second; its matrix is `next.matrix * t.matrix`.

```mbti
pub fn Transform3::compose(Self, Self) -> Self
```

Composition is associative but not commutative. Read a chain from left to right: `scale.compose(rotation).compose(translation)` scales, then rotates, then translates.

### `Transform3::apply_point`

`t.apply_point(p)` maps the point $p$ through $M (p_x, p_y, p_z, 1)^\mathsf{T} = (x', y', z', w')^\mathsf{T}$ and returns $(x'/w', y'/w', z'/w')$.

```mbti
pub fn Transform3::apply_point(Self, @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

For affine transforms $w' = 1$. When $|w'| \le$ `DEPTH_EPSILON` the division is skipped and $(x', y', z')$ is returned.

### `Transform3::apply_direction`

`t.apply_direction(d)` maps the direction $d$ with $w = 0$, so translations do not affect it, and returns the first three components without division.

```mbti
pub fn Transform3::apply_direction(Self, @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

The result is not renormalized. Normals are not transformed this way in the pipeline: they are recomputed from transformed vertices.

### `Transform3::apply_vertex`

`t.apply_vertex(v)` is the same as `t.apply_point(v)`.

```mbti
pub fn Transform3::apply_vertex(Self, @mutable.Vector[Double]) -> @mutable.Vector[Double]
```

### `Transform3::apply_mesh`

`t.apply_mesh(mesh)` returns a new mesh with every vertex mapped by `apply_point` and the same face array.

```mbti
pub fn Transform3::apply_mesh(Self, Mesh) -> Mesh
```

The face array is shared with the input mesh, which is safe because faces are immutable.

```moonbit
test "transforms" {
  let shift = @core.Transform3::translation(1.0, 0.0, 0.0)
  let turn = @core.Transform3::rotation(0.0, 0.0, @math.PI / 2.0)
  let p = @core.vec3(1.0, 0.0, 0.0)
  // rotate first, then translate: (1,0,0) -> (0,1,0) -> (1,1,0)
  let a = turn.compose(shift).apply_point(p)
  inspect((a[0] - 1.0).abs() < 1.0e-12 && (a[1] - 1.0).abs() < 1.0e-12, content="true")
  // translate first, then rotate: (1,0,0) -> (2,0,0) -> (0,2,0)
  let b = shift.compose(turn).apply_point(p)
  inspect((b[1] - 2.0).abs() < 1.0e-12, content="true")
  // directions ignore the translation
  let d = shift.apply_direction(p)
  inspect(d[0], content="1")
  let cube = @core.Transform3::scale(2.0, 2.0, 2.0).apply_mesh(@core.cube_mesh(1.0))
  inspect(cube.vertices[6][0], content="2")
}
```
