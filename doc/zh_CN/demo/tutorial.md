# Demo Tutorial

## 旋转 Cube

```sh
moon run . --target native
```

默认 demo 渲染旋转 cube，包含 dotted background、Z-buffer、backface culling、
flat lighting 和 terminal y-scale correction。

## 静止 Sphere

```sh
moon run . --target native -- --sphere
```

sphere demo 使用较高细分的 UV sphere，并保持静止，方便观察字符明暗变化。

## Smoke Test

```sh
moon run . --target native -- --once
moon run . --target native -- --sphere --once
```

脚本化验证时使用 `--once`，避免进入无限动画循环。
