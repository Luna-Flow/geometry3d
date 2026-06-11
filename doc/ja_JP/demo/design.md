# Demo Design

## Responsibilities

- core と TUI renderer をつなぎます。
- CLI behavior を小さく、予測しやすく保ちます。
- engine concept を追加せず、linear algebra pipeline を示します。

## Defaults

- Cube: rotating、size `1.0`。
- Sphere: static、radius `2.4`、`18` rings、`36` segments。
- Torus: rotating、major radius `2.1`、minor radius `0.72`、outward face winding。
- Hitchcock: central cube と background cylinder、cone、triangular pyramid、その回転変体。
- Renderer: terminal-derived viewport with `80x32` fallback、dotted background、scientific-camera projection、terminal y-scale `0.5`。

## Non-Goals

- Runtime UI、複雑な command parser、config file、interactive controls。
- Persisted scene や asset loading。
- 完全な ASCII art に依存する snapshot tests。
