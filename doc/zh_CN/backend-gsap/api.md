# GSAP SVG 后端 API

该 JS-only 后端把 frontend `DrawList` 三角形渲染为 SVG polygon，并包装宿主
提供的 `globalThis.gsap` 时间线。

## 渲染

- `GsapSvgColor::rgb(red, green, blue)`：将通道限制到 `0..255`。
- `GsapSvgRenderConfig::default()` / `sized(width, height)`：创建配置。
- `render_draw_list(svg, draw_list, config)`：更新可复用 polygon 节点。
- `render_scene(svg, scene, render_view, config)`：构建并渲染 draw list。

三角形按平均深度从远到近排列；相同深度保持输入顺序。

## 播放

`GsapPlayer::new(duration_seconds, on_frame, repeat=-1)` 创建暂停的线性时间线。
播放器提供播放、暂停、反向、重播、定位、进度、时间、倍速、循环、暂停状态
查询和 `kill`。缺少 `globalThis.gsap` 时会抛出 JavaScript 错误。
