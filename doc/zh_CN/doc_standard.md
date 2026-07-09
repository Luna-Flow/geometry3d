# 文档规范

本文档应描述**当前分支真实存在的实现**。当前基线是 **v0.5.1**。

## 文档类型

1. **API Reference (`api.md`)**：公开类型、函数、参数与返回语义。
2. **User Guide (`tutorial.md`)**：实践流程和可运行示例。
3. **Design Documentation (`design.md`)**：架构、约束、扩展点与限制。

## 组织结构

```text
doc/
  en_US/
  zh_CN/
  ja_JP/
    core/
      api.md
      tutorial.md
      design.md
    view/
      api.md
      tutorial.md
      design.md
    frontend/
      api.md
      tutorial.md
      design.md
    backend-tui/
      api.md
      tutorial.md
      design.md
    backend-canvas/
      api.md
      tutorial.md
      design.md
    demo/
      api.md
      tutorial.md
      design.md
```

## 维护规则

- 文档必须和仓库已有代码保持一致。
- 不记录尚未实现的 engine 功能，例如 scene graph、material、texture、
  physics、BVH 或 asset loader。
- geometry core 文档不得混入 terminal、ANSI、TUI 背景等细节。
- terminal y-scale、背景 pattern、字符光栅化只放在 `backend-tui` 或 `demo`；
  browser DOM、Canvas、scanline 和 JS target 细节只放在 `backend-canvas` 或 `demo`。
- 跨层行为变化时，同步更新 API、tutorial 和 design 文档。
