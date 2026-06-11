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

## Rotating Torus

```sh
just torus
```

torus は outward face winding を使うため、backface culling は inner wall ではなく exterior を表示します。`just` は detected terminal dimensions も渡します。

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

default sequence と static-image workflow には `just record`、`just export-image`、`just show-image` を使います。output は ignored `target/` に置かれます。
