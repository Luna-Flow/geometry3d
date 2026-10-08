# Changelog

All notable changes to `Luna-Flow/geometry3d` are listed here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions
follow semantic versioning.

## Unreleased

### Changed

- Migrated to MoonBit 0.10 (`moonc` 0.10 or later is required). The public API
  is unchanged.
- Package manifests use the `moon.pkg` DSL: the executable packages `demo`,
  `demo_canvas` and `demo_gsap` declare `pkgtype(kind: "executable")` instead
  of the `is-main` option.
- `core` and `view` no longer import `Luna-Flow/luna-generic`, which they did
  not use.
- The GSAP backend passes `FixedArray` instead of `Array` across the JavaScript
  FFI, since passing `Array` there is deprecated.
- Source code uses the type-named constructors (`StringBuilder()`) instead of
  the deprecated `::new` forms, and is formatted with the current `moon fmt`.
- The terminal demo reads environment variables through
  `moonbitlang/core/env` instead of the deprecated `moonbitlang/x/sys`, and its
  test-only helpers moved into the whitebox tests.
- `.gitignore` excludes the local state of AI coding assistants.

### Documentation

- Documentation rewritten: every package (`core`, `view`, `frontend`,
  `backend/tui`, `backend/canvas`, `backend/gsap`, `demo`, `demo_canvas`,
  `demo_gsap`) has an API reference, a tutorial with compiling examples, and a
  design note with the derivations behind the code. A new architecture guide
  follows one frame through the packages.
- The manual is fully translated into Chinese (`zh_CN`) and Japanese (`ja_JP`).
- README rewritten for the current version.

## 0.5.1 - 2026-07-09

### Changed

- Compatibility with `Luna-Flow/linear-algebra@0.4.2`, including its split into
  checked and `unchecked_` matrix-vector operations.
- Repository maintenance scripts (`justfile`, `run_test.sh`, publish workflow)
  aligned with the Luna-Flow template.

## 0.5.0 - 2026-06-14

### Added

- `backend/gsap`: SVG polygon rendering with painter's ordering and a GSAP
  timeline player, and the `demo_gsap` browser demo.

## 0.4.1 - 2026-06-14

### Added

- `backend/canvas`: browser Canvas 2D rendering on the frontend's software
  depth buffer, and the `demo_canvas` browser demo.

## 0.3.0 - 2026-06-12

### Added

- Directional-light shadow mapping in the frontend, perspective-correct depth
  interpolation, additional mesh generators, and an expanded terminal demo.

## Earlier versions

- 0.2.0 split the single package into `core`, `view`, `frontend`,
  `backend/tui` and `demo` (see `doc/manual/migration_v0_2.md`), and added the
  scientific camera, luma buffers, exposure and optical-flow accumulation,
  timelines, and the `.tui3d` and `.tuiimg` formats.
