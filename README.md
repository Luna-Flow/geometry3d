# geometry3d

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/geometry3d/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

`geometry3d` is a small 3D rendering pipeline for MoonBit, built on
`Luna-Flow/linear-algebra`. It takes quad meshes through homogeneous
transforms, a look-at camera with a physical lens model, perspective
projection, back-face culling, Lambert shading and shadow mapping, and draws
the result in a terminal, on an HTML canvas, or as GSAP-animated SVG. It is
deliberately not a game engine: it shows how the Luna-Flow math base carries a
complete, readable pipeline, and every stage is documented with the
mathematics it implements.

## Install

```sh
moon add Luna-Flow/geometry3d@0.5.1
```

Add `Luna-Flow/linear-algebra@0.4.7` as well if your code names its vector
types, and `moonbit-community/rabbita@0.12.4` for the browser backends.

## Example

```moonbit
fn main {
  let scene = @frontend.Scene::single(
    @core.torus_mesh(1.6, 0.6, 24, 12),
    @core.Transform3::rotation(1.1, 0.3, 0.0),
    @frontend.Light::default(),
  )
  let view = @frontend.RenderView::perspective(
    @view.Camera3::default(5.0),
    @view.PerspectiveProjection::new(@view.Viewport::new(48, 16), 24.0),
  )
  let config = @tui.TuiRenderConfig::sized(48, 16)
  println(@tui.render_scene(scene, view, config).to_string())
}
```

with these imports in `moon.pkg`:

```text
import {
  "Luna-Flow/geometry3d/core",
  "Luna-Flow/geometry3d/view",
  "Luna-Flow/geometry3d/frontend",
  "Luna-Flow/geometry3d/backend/tui",
}
```

prints a shaded torus as text.

## Packages

| Package | Contents | Targets |
| --- | --- | --- |
| `core` | vectors, quad meshes and generators, normals, visibility, Lambert intensity, 4×4 transforms | all |
| `view` | look-at camera, perspective/orthographic projection, perspective-correct depth, sensor and lens model | all |
| `frontend` | scenes, backend-neutral `DrawList`, shadow mapping, `LumaBuffer`, exposure, optical flow, timelines | all |
| `backend/tui` | character frame buffer, shade ramp, terminal aspect correction, `.tuiimg`/`.tui3d` files | all |
| `backend/canvas` | HTML canvas output with exact occlusion | `js` |
| `backend/gsap` | SVG polygons in painter's order, GSAP playback controller | `js` |
| `demo` | terminal demo: cube, sphere, torus, Hitchcock and dolly-zoom scenes, exposure, recording | `native` |
| `demo_canvas`, `demo_gsap` | browser demos of the two web backends | `js` |

`core`, `view` and `frontend` know nothing about terminals, colours or the
DOM; only the backends and demos do.

## Run the demos

```sh
just torus          # terminal, sized from stty
just hitchcock      # dolly zoom in the terminal
just canvas-serve   # http://localhost:8080
just gsap-serve     # http://localhost:8081
just record         # write target/geometry3d-demo.tui3d
```

`tools/tui3d_to_video.py` converts `.tui3d` recordings to MP4 or MOV; see
[tools/README.md](./tools/README.md).

## Toolchain and tests

MoonBit with `moonc` 0.10 or later is required.

```sh
moon check --target all
bash ./run_test.sh    # tests on wasm-gc, js, native, wasm, plus demo smoke runs
just ready            # fmt, check, info, test matrix, coverage
```

Releases are published by the manually dispatched
`.github/workflows/publish.yml` workflow; `just publish-dry-run` checks the
package locally.

## Documentation

The manual is published at <https://lunaflow.cn/en/geometry3d/> with Chinese
and Japanese translations. Its English source is
[`doc/manual/index.md`](./doc/manual/index.md): an API reference, a tutorial
and a design note with derivations for every package, plus an
[architecture guide](./doc/manual/architecture.md).

## Contributing

Issues and pull requests are welcome at
<https://github.com/Luna-Flow/geometry3d>. Run `just ready` before opening a
pull request, keep commits in Conventional Commits form, and update the API,
tutorial and design pages of every package you change
([conventions](./doc/manual/conventions.md)).

## License

Apache-2.0. See [LICENSE](./LICENSE).
