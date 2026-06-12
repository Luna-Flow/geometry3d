# Canvas 后端 API

Canvas 后端仅支持 JS target。它消费 `@frontend.DrawList`，通过 frontend 中
支持透视校正的 Z-buffer 完成逐像素光栅化，再将连续同色扫描线区间写入浏览器
`CanvasRenderingContext2D`。

## 类型

- `CanvasColor::rgb(red, green, blue)`：将 RGB 通道限制到 `0..255`。
- `CanvasRenderConfig::default()`：创建 `640 x 480` 默认配置。
- `CanvasRenderConfig::sized(width, height)`：创建指定尺寸的默认深色背景、青色前景配置。

## 渲染

- `render_draw_list(context, draw_list, config)`：渲染已有 draw list。
- `render_scene(context, scene, render_view, config)`：构建并渲染 draw list。
- `render_canvas(canvas, draw_list, config)`：设置 Canvas 像素尺寸并完成渲染。

运行 `just canvas-serve`，然后打开 `http://localhost:8080`。页面选择器可以在
旋转 Torus 与 Dolly zoom 场景之间切换。Dolly 与终端 demo 共用旋转立方体、
35 个圆盘背景、相机距离曲线和焦距补偿参数。
