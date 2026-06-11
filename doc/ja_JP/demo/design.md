# Demo Design

## Responsibilities

- core と TUI renderer をつなぎます。
- CLI behavior を小さく、予測しやすく保ちます。
- engine concept を追加せず、linear algebra pipeline を示します。

## Defaults

- Cube: rotating、size `1.0`。
- Sphere: static、radius `2.4`、`18` rings、`36` segments。
- Hitchcock: central cube と background cylinder、cone、triangular pyramid、その回転変体。
- Renderer: `80x32`、dotted background、projection scale `24.0`、terminal y-scale `0.5`。

## Non-Goals

- Runtime UI、複雑な command parser、config file、interactive controls。
- Persisted scene や asset loading。
- 完全な ASCII art に依存する snapshot tests。
