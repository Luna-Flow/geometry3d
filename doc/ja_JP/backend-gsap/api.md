# GSAP SVG Backend API

JS-only backend は frontend `DrawList` の triangle を SVG polygon として描画し、
host が提供する `globalThis.gsap` timeline をラップします。

## Rendering

- `GsapSvgColor::rgb(red, green, blue)`: channel を `0..255` に clamp します。
- `GsapSvgRenderConfig::default()` / `sized(width, height)`: config を作成します。
- `render_draw_list(svg, draw_list, config)`: 再利用可能な polygon node を更新します。
- `render_scene(svg, scene, render_view, config)`: draw list を生成して描画します。

triangle は平均 depth の遠い順に並び、同じ depth では入力順を維持します。

## Playback

`GsapPlayer::new(duration_seconds, on_frame, repeat=-1)` は paused linear timeline
を作成します。play、pause、reverse、restart、seek、progress、time、time scale、
repeat、paused query、kill を提供します。GSAP がない場合は JS error を投げます。
