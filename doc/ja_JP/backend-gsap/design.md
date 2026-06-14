# GSAP SVG Backend Design

## Responsibilities

- backend-neutral frontend `DrawList` を consume します。
- projected triangle を再利用可能な SVG polygon node に書き込みます。
- 平均 depth で遠い順に並べます。
- scene math を MoonBit に残したまま GSAP playback を提供します。

## Boundary and Limitations

package は JS-only で `globalThis.gsap` が必要です。SVG は per-pixel Z-buffer
ではなく DOM paint order を使います。交差 triangle は分割されません。現在は
opaque flat-shaded polygon のみを描画します。
