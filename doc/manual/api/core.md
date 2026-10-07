# Core API

The core layer owns 3D data and math. It does not know about TUI output,
terminal aspect ratio correction, ANSI escape codes, or character backgrounds.

## Types

```moonbit
struct QuadFace { a : Int; b : Int; c : Int; d : Int }
struct TriangleFace { a : Int; b : Int; c : Int }
struct Mesh { vertices : Array[@la.Vector[Double]]; faces : Array[QuadFace] }
struct Transform3 { matrix : @la.Matrix[Double] }
```

## Mesh Construction

- `cube_mesh(size : Double) -> Mesh`: creates a cube centered at the origin.
- `sphere_mesh(radius : Double, rings : Int, segments : Int) -> Mesh`: creates a
  low-poly UV sphere represented as quad faces, with degenerate quads at the caps.
- `torus_mesh(major_radius, minor_radius, major_segments, minor_segments) -> Mesh`:
  creates an outward-wound quad torus suitable for backface culling.
- `face_vertices(mesh : Mesh, face : QuadFace) -> Array[@la.Vector[Double]]`:
  returns the four vertices referenced by a face.
- `triangulate_quad(face : QuadFace) -> Array[TriangleFace]`: splits a quad into
  two triangles for rasterization.

## Vector Helpers

- `vec3(x, y, z)`: constructs a 3D vector.
- `sub_vec(a, b)`: subtracts two vectors.
- `cross_vec(a, b)`: computes a 3D cross product.
- `vec_length(v)`: computes Euclidean length.
- `normalize_vec(v)`: returns a unit vector or zero vector for near-zero input.

## Face Helpers

- `face_center(vertices, face)`: average of the four face vertices.
- `face_normal(vertices, face)`: normalized cross product from the first three face vertices.
- `face_is_visible(vertices, face, camera_position)`: backface test using `normal dot to_camera`.
- `face_intensity(vertices, face, light_direction)`: simple Lambert intensity clamped at zero.

## Transform Helpers

- `Transform3::identity()`: identity 4x4 transform.
- `Transform3::translation(x, y, z)`: point translation.
- `Transform3::scale(x, y, z)`: non-uniform scale.
- `rotation_x(angle)`, `rotation_y(angle)`, `rotation_z(angle)`: 4x4 rotation matrices.
- `rotation_matrix(angle_x, angle_y, angle_z)`: combined `Z * Y * X` rotation.
- `Transform3::rotation(angle_x, angle_y, angle_z)`: 4x4 rotation transform.
- `Transform3::compose(next)`: applies `self` then `next`.
- `Transform3::apply_point(point)`: applies the full homogeneous transform.
- `Transform3::apply_direction(direction)`: ignores translation by using `w = 0`.
- `Transform3::apply_vertex(vertex)`: applies the transform matrix to one vertex.
- `Transform3::apply_mesh(mesh)`: transforms vertices and preserves face topology.
