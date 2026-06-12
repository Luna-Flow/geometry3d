# Canvas 后端教程

构建并启动浏览器 demo：

```sh
just canvas-serve
```

打开 `http://localhost:8080`，通过选择器切换 Torus 与 Dolly zoom。构建产物位于
`target/canvas-demo`。

应用代码可以通过 `moonbit-community/rabbita/dom` 获取
`CanvasRenderingContext2D`，构建 frontend draw list 后调用 `render_draw_list`；
需要由后端从 `Scene` 和 `RenderView` 构建 draw list 时使用 `render_scene`。
