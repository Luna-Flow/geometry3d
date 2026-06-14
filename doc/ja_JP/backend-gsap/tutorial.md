# GSAP SVG Backend Tutorial

```sh
just gsap-serve
```

`http://localhost:8081` を開きます。demo は固定 version の GSAP ESM を読み込み、
`globalThis.gsap` を設定してから MoonBit output を読み込みます。

SVG element と frontend `DrawList` を `render_draw_list` に渡します。animation は
`GsapPlayer` の frame callback に渡される秒から scene を再構築します。破棄時には
`kill` を呼びます。
