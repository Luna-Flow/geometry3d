///|
const WIDTH : Int = 640

///|
const HEIGHT : Int = 480

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
fn torus_scene(timestamp : Double) -> @frontend.Scene {
  let angle = timestamp * 0.0006
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
fn dolly_frame(timestamp : Double) -> Int {
  (timestamp / 33.333333333333336).floor().to_int()
}

///|
fn dolly_distance(frame : Int) -> Double {
  let wave = (@math.sin(frame.to_double() * 0.028) + 1.0) * 0.5
  DOLLY_NEAR_DISTANCE + (DOLLY_FAR_DISTANCE - DOLLY_NEAR_DISTANCE) * wave
}

///|
fn dolly_focal_length_mm(distance : Double) -> Double {
  DOLLY_BASE_FOCAL_MM * distance / DOLLY_BASE_DISTANCE
}

///|
fn dolly_render_view(frame : Int) -> @frontend.RenderView {
  let distance = dolly_distance(frame)
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
fn dolly_scene(frame : Int) -> @frontend.Scene {
  let scene = @frontend.Scene::new(
    @frontend.Light::directional(@core.vec3(-0.35, 0.7, -1.0)),
  )
  let time = frame.to_double()
  scene.add_object(
    @frontend.SceneObject::new(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(time * 0.041, time * 0.057, time * 0.023).compose(
        @core.Transform3::scale(1.35, 1.35, 1.35),
      ),
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
  context : @dom.CanvasRenderingContext2D,
  timestamp : Double,
  selected : DemoKind,
) -> Unit {
  let (scene, render_view) = match selected {
    Torus => (torus_scene(timestamp), torus_render_view())
    Dolly => {
      let frame = dolly_frame(timestamp)
      (dolly_scene(frame), dolly_render_view(frame))
    }
  }
  @canvas.render_scene(
    context,
    scene,
    render_view,
    @canvas.CanvasRenderConfig::sized(WIDTH, HEIGHT),
  )
}

///|
fn main {
  let canvas = @dom.document()
    .get_element_by_id("geometry3d-canvas")
    .to_option()
    .unwrap()
    .to_html_canvas_element()
    .unwrap()
  canvas.set_attribute("width", WIDTH.to_string())
  canvas.set_attribute("height", HEIGHT.to_string())
  let context = canvas.get_context("2d").to0().unwrap()
  let selector_element = @dom.document()
    .get_element_by_id("demo-select")
    .to_option()
    .unwrap()
  let selector = selector_element.to_html_select_element().unwrap()
  let selected : Ref[DemoKind] = { val: demo_kind(selector.value()) }
  selector_element.add_event_listener("change", fn(_) {
    selected.val = demo_kind(selector.value())
  })
  let window = @dom.window()
  fn frame(timestamp : Double) -> Unit {
    render_frame(context, timestamp, selected.val)
    ignore(window.request_animation_frame(frame))
  }
  ignore(window.request_animation_frame(frame))
}
