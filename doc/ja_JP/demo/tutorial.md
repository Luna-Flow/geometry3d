# Demo Tutorial

## Rotating Cube

```sh
moon run src/demo --target native
```

default demo は dotted background、Z-buffer、backface culling、flat lighting、
terminal y-scale correction を使って rotating cube を描画します。

## Static Sphere

```sh
moon run src/demo --target native -- --sphere
```

sphere demo は高めの subdivision の UV sphere を使い、lighting を見やすくするため静止します。

## Hitchcock Zoom Scene

```sh
moon run src/demo --target native -- --hitchcock
```

central cube の見た目の大きさを保ちながら、camera distance と projection scale を
連動させます。cube の後方に cylinder、cone、triangular pyramid とその回転変体を置き、
dolly zoom effect を見やすくします。

## Smoke Test

```sh
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --hitchcock --once
```

script や local check では `--once` を使うと infinite animation loop を避けられます。
