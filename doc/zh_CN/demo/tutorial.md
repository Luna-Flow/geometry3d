# Demo Tutorial

## 旋转 Cube

```sh
moon run src/demo --target native
```

默认 demo 渲染旋转 cube，包含 dotted background、Z-buffer、backface culling、
flat lighting 和 terminal y-scale correction。

## 静止 Sphere

```sh
moon run src/demo --target native -- --sphere
```

sphere demo 使用较高细分的 UV sphere，并保持静止，方便观察字符明暗变化。

## 旋转 Torus

```sh
just torus
```

torus 的面绕序朝外，因此背面剔除会显示外表面而不是内壁。`just` 会自动传入检测到的终端尺寸。

## Hitchcock Zoom 场景

```sh
moon run src/demo --target native -- --hitchcock
```

该场景让中心 cube 在视觉上保持稳定，同时联动 camera distance 和 projection scale。
圆柱、圆锥、三棱锥及其旋转变体位于 cube 后方，用来凸显 dolly zoom 的空间压缩效果。

## Smoke Test

```sh
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --hitchcock --once
```

脚本化验证时使用 `--once`，避免进入无限动画循环。

使用 `just record`、`just export-image` 和 `just show-image` 执行默认序列与静态图流程，产物写入已忽略的 `target/`。
