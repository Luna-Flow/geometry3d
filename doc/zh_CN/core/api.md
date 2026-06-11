# Core API

core 层负责 3D 数据和数学关系，不知道 TUI 输出、终端宽高比、ANSI 控制符或字符背景。

## 类型

```moonbit
struct QuadFace { a : Int; b : Int; c : Int; d : Int }
struct TriangleFace { a : Int; b : Int; c : Int }
struct Mesh { vertices : Array[@la.Vector[Double]]; faces : Array[QuadFace] }
struct Transform3 { matrix : @la.Matrix[Double] }
```

## Mesh

- `cube_mesh(size)`：创建以原点为中心的 cube。
- `sphere_mesh(radius, rings, segments)`：创建 quad 拓扑的低多边形 UV sphere，极点使用退化 quad。
- `face_vertices(mesh, face)`：取出 face 引用的四个顶点。
- `triangulate_quad(face)`：将 quad 拆成两个 triangle。

## 向量与面 helper

- `vec3`、`sub_vec`、`cross_vec`、`vec_length`、`normalize_vec`。
- `face_center`：四个顶点的平均位置。
- `face_normal`：基于前三个顶点的归一化叉积。
- `face_is_visible`：`normal dot to_camera` 背面剔除判断。
- `face_intensity`：简单 Lambert 光照强度。

## Transform

- `rotation_x/y/z(angle)`：3x3 旋转矩阵。
- `rotation_matrix(angle_x, angle_y, angle_z)`：组合 `Z * Y * X`。
- `Transform3::rotation(...)`：旋转 transform。
- `Transform3::apply_vertex(vertex)`：矩阵乘向量。
- `Transform3::apply_mesh(mesh)`：变换顶点并保留 face 拓扑。
