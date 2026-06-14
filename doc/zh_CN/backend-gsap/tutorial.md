# GSAP SVG 后端教程

```sh
just gsap-serve
```

打开 `http://localhost:8081`。demo 加载固定版本 GSAP ESM，写入
`globalThis.gsap` 后再加载 MoonBit 产物。

应用可向 `render_draw_list` 传入 SVG 元素和 frontend `DrawList`。动画场景在
`GsapPlayer` 帧回调中根据传入秒数重建。页面或组件销毁时应调用 `kill`。
