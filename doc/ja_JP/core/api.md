# Core API

core layer は 3D データと数学的関係を扱います。TUI 出力、terminal aspect
ratio、ANSI escape、character background は扱いません。

## Types

```moonbit
struct QuadFace { a : Int; b : Int; c : Int; d : Int }
struct TriangleFace { a : Int; b : Int; c : Int }
struct Mesh { vertices : Array[@la.Vector[Double]]; faces : Array[QuadFace] }
struct Transform3 { matrix : @la.Matrix[Double] }
```

## Mesh

- `cube_mesh(size)`: 原点中心の cube を作成します。
- `sphere_mesh(radius, rings, segments)`: quad topology の low-poly UV sphere を作成します。
- `face_vertices(mesh, face)`: face が参照する 4 つの vertex を返します。
- `triangulate_quad(face)`: quad を 2 つの triangle に分割します。

## Vector And Face Helpers

- `vec3`、`sub_vec`、`cross_vec`、`vec_length`、`normalize_vec`。
- `face_center`: 4 vertex の平均位置。
- `face_normal`: 最初の 3 vertex から計算した normalized cross product。
- `face_is_visible`: `normal dot to_camera` による backface test。
- `face_intensity`: simple Lambert lighting。

## Transform

- `rotation_x/y/z(angle)`: 3x3 rotation matrix。
- `rotation_matrix(angle_x, angle_y, angle_z)`: `Z * Y * X` の合成。
- `Transform3::rotation(...)`: rotation transform。
- `Transform3::apply_vertex(vertex)`: matrix-vector multiplication。
- `Transform3::apply_mesh(mesh)`: vertex を変換し、face topology を保持します。
