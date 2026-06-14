///|
fn test_triangle(depth : Double, intensity : Double) -> @frontend.DrawTriangle {
  @frontend.DrawTriangle::new(
    @view.ProjectedVertex::new(1.0, 2.0, depth),
    @view.ProjectedVertex::new(3.0, 4.0, depth),
    @view.ProjectedVertex::new(5.0, 6.0, depth),
    intensity,
  )
}

///|
extern "js" fn install_gsap_stub() -> Unit =
  #| () => {
  #|   globalThis.gsap = {
  #|     timeline(options) {
  #|       let time = 0;
  #|       let progress = 0;
  #|       let timeScale = 1;
  #|       let repeat = options.repeat;
  #|       let paused = options.paused;
  #|       return {
  #|         to(clock, vars) {
  #|           this.clock = clock;
  #|           this.vars = vars;
  #|           this.duration = vars.duration;
  #|           return this;
  #|         },
  #|         play() { paused = false; return this; },
  #|         pause() { paused = true; return this; },
  #|         reverse() { paused = false; return this; },
  #|         restart() { time = 0; progress = 0; paused = false; return this; },
  #|         time(value) {
  #|           if (value === undefined) return time;
  #|           time = value;
  #|           progress = this.duration > 0 ? value / this.duration : 0;
  #|           this.clock.time = value;
  #|           this.vars.onUpdate();
  #|           return this;
  #|         },
  #|         progress(value) {
  #|           if (value === undefined) return progress;
  #|           progress = value;
  #|           time = value * this.duration;
  #|           this.clock.time = time;
  #|           this.vars.onUpdate();
  #|           return this;
  #|         },
  #|         timeScale(value) {
  #|           if (value === undefined) return timeScale;
  #|           timeScale = value;
  #|           return this;
  #|         },
  #|         repeat(value) {
  #|           if (value === undefined) return repeat;
  #|           repeat = value;
  #|           return this;
  #|         },
  #|         paused() { return paused; },
  #|         kill() { this.killed = true; },
  #|       };
  #|     },
  #|   };
  #| }

///|
test "gsap svg config normalizes values" {
  let config = normalized_config({
    width: 0,
    height: -1,
    background_color: { red: -1, green: 20, blue: 300 },
    foreground_color: { red: 12, green: 34, blue: 56 },
    shade_levels: 1,
  })
  assert_eq(config.width, 640)
  assert_eq(config.height, 480)
  assert_eq(config.background_color.red, 0)
  assert_eq(config.background_color.blue, 255)
  assert_eq(config.shade_levels, 2)
}

///|
test "gsap svg serializes points and quantized color" {
  let triangle = test_triangle(3.0, 0.5)
  assert_eq(triangle_points(triangle), "1,2 3,4 5,6")
  assert_eq(
    shade_css(GsapSvgColor::rgb(100, 200, 250), 0.0, 256),
    "rgb(0, 0, 0)",
  )
  assert_eq(
    shade_css(GsapSvgColor::rgb(100, 200, 250), 1.0, 256),
    "rgb(100, 200, 250)",
  )
}

///|
test "gsap svg orders far triangles first and keeps ties stable" {
  let draw_list = @frontend.DrawList::new()
  draw_list.push_triangle(test_triangle(2.0, 0.1))
  draw_list.push_triangle(test_triangle(8.0, 0.2))
  draw_list.push_triangle(test_triangle(8.0, 0.3))
  let ordered = ordered_triangles(draw_list)
  assert_eq(ordered[0].source_index, 1)
  assert_eq(ordered[1].source_index, 2)
  assert_eq(ordered[2].source_index, 0)
}

///|
test "gsap player delegates playback and clamps public controls" {
  install_gsap_stub()
  let sampled_time : Ref[Double] = { val: -1.0 }
  let player = GsapPlayer::new(4.0, fn(time) { sampled_time.val = time })
  assert_eq(sampled_time.val, 0.0)
  assert_true(player.is_paused())
  player.play()
  assert_false(player.is_paused())
  player.pause()
  assert_true(player.is_paused())
  player.seek(8.0)
  assert_eq(player.time(), 4.0)
  assert_eq(sampled_time.val, 4.0)
  player.set_progress(-1.0)
  assert_eq(player.progress(), 0.0)
  player.set_progress(0.25)
  assert_eq(player.time(), 1.0)
  player.set_time_scale(0.0)
  assert_eq(player.time_scale(), 1.0)
  player.set_time_scale(2.0)
  assert_eq(player.time_scale(), 2.0)
  player.reverse()
  assert_false(player.is_paused())
  player.kill()
}
