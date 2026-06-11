# Core Tutorial

## 创建 Mesh

```moonbit
let cube = cube_mesh(1.0)
let sphere = sphere_mesh(2.4, 18, 36)
```

两者都使用 `@la.Vector[Double]` 顶点和 `QuadFace` 拓扑。

## 变换 Mesh

```moonbit
let transform = Transform3::rotation(0.2, 0.4, 0.0)
let transformed = transform.apply_mesh(cube)
```

变换层继续使用 `Luna-Flow/linear-algebra` 的矩阵构造、矩阵乘法和 `mul_vec`。

## 读取面几何关系

```moonbit
let face = transformed.faces[0]
let normal = face_normal(transformed.vertices, face)
let center = face_center(transformed.vertices, face)
let visible = face_is_visible(transformed.vertices, face, vec3(0.0, 0.0, -4.5))
```

这些 helper 应在投影或渲染前使用，并且不依赖任何屏幕尺寸或 backend。
