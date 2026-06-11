# View Design

## Responsibilities

- world-space point/direction を camera space に変換します。
- camera-space point を viewport coordinates に投影します。
- terminal、ANSI、backend の詳細を含めません。

## Conventions

camera space では正の `z` が camera の前方です。`look_at` は `right`、
`true_up`、`forward` basis から view transform を作ります。
