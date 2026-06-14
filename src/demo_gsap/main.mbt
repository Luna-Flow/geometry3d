///|
const WIDTH : Int = 640

///|
const HEIGHT : Int = 480

///|
const DURATION_SECONDS : Double = 8.0

///|
const DOLLY_BASE_DISTANCE : Double = 3.2

///|
const DOLLY_NEAR_DISTANCE : Double = 3.2

///|
const DOLLY_FAR_DISTANCE : Double = 69.56521739130434

///|
const DOLLY_BASE_FOCAL_MM : Double = 23.0

///|
const DOLLY_WALL_Z : Double = 5.0

///|
enum DemoKind {
  Torus
  Dolly
}

///|
fn demo_kind(value : String) -> DemoKind {
  if value == "dolly" {
    Dolly
  } else {
    Torus
  }
}

///|
fn scaled_translated(
  scale_x : Double,
  scale_y : Double,
  scale_z : Double,
  x : Double,
  y : Double,
  z : Double,
) -> @core.Transform3 {
  @core.Transform3::scale(scale_x, scale_y, scale_z).compose(
    @core.Transform3::translation(x, y, z),
  )
}

///|
fn torus_scene(time_seconds : Double) -> @frontend.Scene {
  let angle = time_seconds * 1.8
  @frontend.Scene::single(
    @core.torus_mesh(1.7, 0.58, 32, 18),
    @core.Transform3::rotation(angle * 0.7, angle, angle * 0.25),
    @frontend.Light::default(),
  )
}

///|
fn torus_render_view() -> @frontend.RenderView {
  let viewport = @view.Viewport::new(WIDTH, HEIGHT)
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(6.2),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(35.0),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(camera, viewport)
}

///|
fn dolly_distance(time_seconds : Double) -> Double {
  let wave = (@math.sin(time_seconds * @math.PI * 0.5) + 1.0) * 0.5
  DOLLY_NEAR_DISTANCE + (DOLLY_FAR_DISTANCE - DOLLY_NEAR_DISTANCE) * wave
}

///|
fn dolly_focal_length_mm(distance : Double) -> Double {
  DOLLY_BASE_FOCAL_MM * distance / DOLLY_BASE_DISTANCE
}

///|
fn dolly_render_view(time_seconds : Double) -> @frontend.RenderView {
  let distance = dolly_distance(time_seconds)
  let viewport = @view.Viewport::new(WIDTH, HEIGHT)
  let camera = @view.ScientificCamera::new(
    @view.Camera3::default(distance),
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(dolly_focal_length_mm(distance)),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(camera, viewport)
}

///|
fn dolly_scene(time_seconds : Double) -> @frontend.Scene {
  let scene = @frontend.Scene::new(
    @frontend.Light::directional(@core.vec3(-0.35, 0.7, -1.0)),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(
        time_seconds * 1.23,
        time_seconds * 1.71,
        time_seconds * 0.69,
      ).compose(@core.Transform3::scale(1.35, 1.35, 1.35)),
    ),
  )
  let disc = @core.cylinder_mesh(0.58, 0.10, 20)
  for row in 0..<5 {
    for column in 0..<7 {
      let x = (column - 3).to_double() * 2.32
      let y = (2 - row).to_double() * 2.32
      scene.add_object(
        @frontend.SceneObject::new(
          disc,
          @core.Transform3::rotation(@math.PI * 0.5, 0.0, 0.0).compose(
            scaled_translated(1.0, 1.0, 1.0, x, y, DOLLY_WALL_Z),
          ),
        ),
      )
    }
  }
  scene
}

///|
fn render_frame(
  svg : @dom.Element,
  time_seconds : Double,
  selected : DemoKind,
) -> Unit {
  let (scene, render_view) = match selected {
    Torus => (torus_scene(time_seconds), torus_render_view())
    Dolly => (dolly_scene(time_seconds), dolly_render_view(time_seconds))
  }
  @gsap.render_scene(
    svg,
    scene,
    render_view,
    @gsap.GsapSvgRenderConfig::sized(WIDTH, HEIGHT),
  )
}

///|
extern "js" fn sync_progress(time : Double, duration : Double) -> Unit =
  #| (time, duration) => {
  #|   const progress = document.getElementById("progress");
  #|   const readout = document.getElementById("time-readout");
  #|   if (progress && document.activeElement !== progress) {
  #|     progress.value = String(duration > 0 ? time / duration : 0);
  #|   }
  #|   if (readout) readout.textContent = `${time.toFixed(2)} / ${duration.toFixed(2)}s`;
  #| }

///|
extern "js" fn sync_play_state(paused : Bool) -> Unit =
  #| (paused) => {
  #|   const button = document.getElementById("play-toggle");
  #|   if (button) button.textContent = paused ? "PLAY" : "PAUSE";
  #| }

///|
extern "js" fn bind_controls(
  on_demo : (String) -> Unit,
  on_toggle : () -> Unit,
  on_reverse : () -> Unit,
  on_restart : () -> Unit,
  on_progress : (Double) -> Unit,
  on_speed : (Double) -> Unit,
  on_loop : (Bool) -> Unit,
) -> Unit =
  #| (onDemo, onToggle, onReverse, onRestart, onProgress, onSpeed, onLoop) => {
  #|   document.getElementById("demo-select").addEventListener("change", event => onDemo(event.target.value));
  #|   document.getElementById("play-toggle").addEventListener("click", onToggle);
  #|   document.getElementById("reverse").addEventListener("click", onReverse);
  #|   document.getElementById("restart").addEventListener("click", onRestart);
  #|   document.getElementById("progress").addEventListener("input", event => onProgress(Number(event.target.value)));
  #|   document.getElementById("speed").addEventListener("change", event => onSpeed(Number(event.target.value)));
  #|   document.getElementById("loop").addEventListener("change", event => onLoop(event.target.checked));
  #| }

///|
fn main {
  let svg = @dom.document()
    .get_element_by_id("geometry3d-svg")
    .to_option()
    .unwrap()
  let selected : Ref[DemoKind] = { val: Torus }
  let player = @gsap.GsapPlayer::new(
    DURATION_SECONDS,
    fn(time_seconds) {
      render_frame(svg, time_seconds, selected.val)
      sync_progress(time_seconds, DURATION_SECONDS)
    },
    repeat=-1,
  )
  bind_controls(
    fn(value) {
      selected.val = demo_kind(value)
      render_frame(svg, player.time(), selected.val)
    },
    fn() {
      if player.is_paused() {
        player.play()
      } else {
        player.pause()
      }
      sync_play_state(player.is_paused())
    },
    fn() {
      player.reverse()
      sync_play_state(player.is_paused())
    },
    fn() {
      player.restart()
      sync_play_state(player.is_paused())
    },
    fn(progress) { player.set_progress(progress) },
    fn(scale) { player.set_time_scale(scale) },
    fn(looping) { player.set_repeat(if looping { -1 } else { 0 }) },
  )
  player.play()
  sync_play_state(false)
}
