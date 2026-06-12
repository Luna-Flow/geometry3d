# Documentation Standard

This repository's documentation should describe the **current implementation on
the branch**. The active baseline is **v0.4.0**.

## Document Types

1. **API Reference (`api.md`)**: public types, functions, parameters, and return semantics.
2. **User Guide (`tutorial.md`)**: practical workflows and runnable examples.
3. **Design Documentation (`design.md`)**: architecture, invariants, extension points, and limitations.

## Organization

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

## Documentation Rules

- Keep the documentation aligned with the code that exists in the repository.
- Do not document speculative engine features such as scene graphs, materials,
  textures, physics, BVH, or asset loaders unless they are implemented.
- Keep geometry core documentation free of terminal, ANSI, and TUI concerns.
- Keep terminal-specific details under `backend-tui` or `demo`, and browser DOM,
  Canvas, scanline, and JS-target details under `backend-canvas` or `demo`.
- Update API, tutorial, and design pages together when behavior crosses subsystem boundaries.
