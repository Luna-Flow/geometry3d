# Demo Tutorial

## Rotating Cube

```sh
moon run . --target native
```

default demo は dotted background、Z-buffer、backface culling、flat lighting、
terminal y-scale correction を使って rotating cube を描画します。

## Static Sphere

```sh
moon run . --target native -- --sphere
```

sphere demo は高めの subdivision の UV sphere を使い、lighting を見やすくするため静止します。

## Smoke Test

```sh
moon run . --target native -- --once
moon run . --target native -- --sphere --once
```

script や local check では `--once` を使うと infinite animation loop を避けられます。
