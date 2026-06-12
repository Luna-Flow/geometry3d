///|
const FRAME_INTERVAL_MS : UInt64 = 33UL

///|
const ANGLE_STEP_X : Double = 0.05

///|
const ANGLE_STEP_Y : Double = 0.035

///|
const ANGLE_STEP_Z : Double = 0.02

///|
const DEFAULT_CAMERA_DISTANCE : Double = 4.5

///|
const DEFAULT_FOCAL_LENGTH_MM : Double = 18.0

///|
const TORUS_CAMERA_DISTANCE : Double = 6.8

///|
const TORUS_FOCAL_LENGTH_MM : Double = 18.0

///|
const HITCHCOCK_BASE_DISTANCE : Double = 4.5

///|
const HITCHCOCK_NEAR_DISTANCE : Double = 3.4

///|
const HITCHCOCK_FAR_DISTANCE : Double = 8.0

///|
const HITCHCOCK_BASE_FOCAL_MM : Double = 18.0

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
const EXPOSURE_FRAME_DT : Double = 1.0 / 30.0

///|
const EXPOSURE_SHUTTER_DENOMINATOR : Double = 30.0

///|
const EXPOSURE_ACCUMULATION_SAMPLES : Int = 12

///|
fn has_arg(args : Array[String], name : String) -> Bool {
  args.iter().any(fn(arg) { arg == name })
}

///|
fn arg_value(args : Array[String], name : String) -> String? {
  for i in 0..<args.length() {
    if args[i] == name && i + 1 < args.length() {
      return Some(args[i + 1])
    }
  }
  None
}

///|
fn digit_value(ch : Char) -> Int {
  if ch == '0' {
    0
  } else if ch == '1' {
    1
  } else if ch == '2' {
    2
  } else if ch == '3' {
    3
  } else if ch == '4' {
    4
  } else if ch == '5' {
    5
  } else if ch == '6' {
    6
  } else if ch == '7' {
    7
  } else if ch == '8' {
    8
  } else if ch == '9' {
    9
  } else {
    -1
  }
}

///|
fn parse_positive_int(text : String, fallback : Int) -> Int {
  let mut value = 0
  let mut seen_digit = false
  for ch in text {
    let digit = digit_value(ch)
    if digit >= 0 {
      value = value * 10 + digit
      seen_digit = true
    }
  }
  if seen_digit && value > 0 {
    value
  } else {
    fallback
  }
}

///|
fn env_positive_int(
  envs : Map[String, String],
  key : String,
  fallback : Int,
) -> Int {
  match envs.get(key) {
    Some(value) => parse_positive_int(value, fallback)
    None => fallback
  }
}

///|
fn auto_viewport() -> @view.Viewport {
  let envs = @sys.get_env_vars()
  let width = env_positive_int(envs, "COLUMNS", @tui.DEFAULT_WIDTH)
  let raw_height = env_positive_int(envs, "LINES", @tui.DEFAULT_HEIGHT + 1)
  // Leave one row for the shell prompt to avoid scroll churn.
  let height = if raw_height > 1 { raw_height - 1 } else { @tui.DEFAULT_HEIGHT }
  @view.Viewport::new(width, height)
}

///|
fn auto_render_config() -> @tui.TuiRenderConfig {
  let viewport = auto_viewport()
  @tui.TuiRenderConfig::sized(viewport.width, viewport.height)
}

///|
fn timeline_from_args(args : Array[String]) -> @frontend.Timeline {
  let duration = match arg_value(args, "--duration") {
    Some(value) => parse_positive_int(value, 3).to_double()
    None => 3.0
  }
  let fps = match arg_value(args, "--fps") {
    Some(value) => parse_positive_int(value, 30)
    None => 30
  }
  @frontend.Timeline::new(duration, fps)
}

///|
fn demo_mesh(args : Array[String]) -> @core.Mesh {
  if has_arg(args, "--sphere") {
    @core.sphere_mesh(2.4, 18, 36)
  } else if has_arg(args, "--torus") {
    @core.torus_mesh(2.1, 0.72, 28, 16)
  } else {
    @core.cube_mesh(1.0)
  }
}

///|
fn demo_should_rotate(args : Array[String]) -> Bool {
  !has_arg(args, "--sphere")
}

///|
fn default_render_view(
  distance : Double,
  focal_length_mm : Double,
) -> @frontend.RenderView {
  let viewport = auto_viewport()
  let camera = @view.Camera3::default(distance)
  let scientific = @view.ScientificCamera::new(
    camera,
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(focal_length_mm),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(scientific, viewport)
}

///|
fn demo_render_view() -> @frontend.RenderView {
  default_render_view(DEFAULT_CAMERA_DISTANCE, DEFAULT_FOCAL_LENGTH_MM)
}

///|
fn torus_render_view() -> @frontend.RenderView {
  default_render_view(TORUS_CAMERA_DISTANCE, TORUS_FOCAL_LENGTH_MM)
}

///|
fn demo_render_view_for_args(args : Array[String]) -> @frontend.RenderView {
  if has_arg(args, "--torus") {
    torus_render_view()
  } else {
    demo_render_view()
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
fn hitchcock_distance(frame : Int) -> Double {
  let t = @math.sin(frame.to_double() * 0.035)
  let midpoint = (HITCHCOCK_NEAR_DISTANCE + HITCHCOCK_FAR_DISTANCE) * 0.5
  let amplitude = (HITCHCOCK_FAR_DISTANCE - HITCHCOCK_NEAR_DISTANCE) * 0.5
  midpoint + amplitude * t
}

///|
fn hitchcock_focal_length_mm(distance : Double) -> Double {
  HITCHCOCK_BASE_FOCAL_MM * distance / HITCHCOCK_BASE_DISTANCE
}

///|
fn hitchcock_render_view(frame : Int) -> @frontend.RenderView {
  let distance = hitchcock_distance(frame)
  let viewport = auto_viewport()
  let camera = @view.Camera3::default(distance)
  let scientific = @view.ScientificCamera::new(
    camera,
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(hitchcock_focal_length_mm(distance)),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(scientific, viewport)
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
  let viewport = auto_viewport()
  let camera = @view.Camera3::default(distance)
  let scientific = @view.ScientificCamera::new(
    camera,
    @view.SensorSpec::full_frame(),
    @view.LensSpec::new(dolly_focal_length_mm(distance)),
    @view.WorldUnit::unitless(),
  )
  @frontend.RenderView::scientific(scientific, viewport)
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
      let z = DOLLY_WALL_Z
      scene.add_object(
        @frontend.SceneObject::new(
          disc,
          @core.Transform3::rotation(@math.PI * 0.5, 0.0, 0.0).compose(
            scaled_translated(1.0, 1.0, 1.0, x, y, z),
          ),
        ),
      )
    }
  }
  scene
}

///|
fn hitchcock_scene() -> @frontend.Scene {
  let scene = @frontend.Scene::new(
    @frontend.Light::directional(@core.vec3(0.5, 0.8, -1.0)),
  )
  let cylinder = @core.cylinder_mesh(1.0, 2.4, 28)
  let cone = @core.cone_mesh(1.15, 2.6, 32)
  let pyramid = @core.triangular_pyramid_mesh(1.35, 2.7)
  scene.add_object(
    @frontend.SceneObject::new(
      @core.cube_mesh(1.0),
      @core.Transform3::rotation(0.62, -0.79, 0.79).compose(
        @core.Transform3::scale(1.55, 1.55, 1.55),
      ),
    ),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      cylinder,
      @core.Transform3::rotation(0.25, 0.0, 0.55).compose(
        scaled_translated(1.4, 1.5, 1.4, -4.2, 0.9, 2.8),
      ),
    ),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      cone,
      @core.Transform3::rotation(-0.2, 0.35, -0.25).compose(
        scaled_translated(1.45, 1.65, 1.45, 2.8, 0.6, 3.1),
      ),
    ),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      pyramid,
      @core.Transform3::rotation(0.1, -0.5, 0.25).compose(
        scaled_translated(1.65, 1.7, 1.65, 0.0, 1.8, 4.2),
      ),
    ),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      cylinder,
      @core.Transform3::rotation(1.25, 0.4, -0.15).compose(
        scaled_translated(1.2, 1.25, 1.2, -1.8, -1.35, 3.7),
      ),
    ),
  )
  scene.add_object(
    @frontend.SceneObject::new(
      cone,
      @core.Transform3::rotation(0.75, -0.55, 0.35).compose(
        scaled_translated(1.2, 1.35, 1.2, 4.6, -1.05, 4.3),
      ),
    ),
  )
  scene
}

///|
fn mesh_frame(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> String {
  mesh_frame_with_view(mesh, angle_x, angle_y, angle_z, demo_render_view())
}

///|
fn mesh_frame_with_view(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  render_view : @frontend.RenderView,
) -> String {
  let transform = @core.Transform3::rotation(angle_x, angle_y, angle_z)
  let scene = @frontend.Scene::single(
    mesh,
    transform,
    @frontend.Light::default(),
  )
  let draw_list = @frontend.build_draw_list(scene, render_view)
  @tui.render_frame(draw_list, auto_render_config())
}

///|
fn mesh_luma(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> @frontend.LumaBuffer {
  mesh_luma_with_view(mesh, angle_x, angle_y, angle_z, demo_render_view())
}

///|
fn mesh_luma_with_view(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  render_view : @frontend.RenderView,
) -> @frontend.LumaBuffer {
  let transform = @core.Transform3::rotation(angle_x, angle_y, angle_z)
  let scene = @frontend.Scene::single(
    mesh,
    transform,
    @frontend.Light::default(),
  )
  let draw_list = @frontend.build_draw_list(scene, render_view)
  @tui.draw_list_to_tui_luma(draw_list, auto_render_config())
}

///|
fn hitchcock_frame(frame : Int) -> String {
  let draw_list = @frontend.build_draw_list(
    hitchcock_scene(),
    hitchcock_render_view(frame),
  )
  @tui.render_frame(draw_list, auto_render_config())
}

///|
fn hitchcock_luma(frame : Int) -> @frontend.LumaBuffer {
  let draw_list = @frontend.build_draw_list(
    hitchcock_scene(),
    hitchcock_render_view(frame),
  )
  @tui.draw_list_to_tui_luma(draw_list, auto_render_config())
}

///|
fn dolly_frame(frame : Int) -> String {
  let draw_list = @frontend.build_draw_list(
    dolly_scene(frame),
    dolly_render_view(frame),
  )
  @tui.render_frame(draw_list, auto_render_config())
}

///|
fn dolly_luma(frame : Int) -> @frontend.LumaBuffer {
  let draw_list = @frontend.build_draw_list(
    dolly_scene(frame),
    dolly_render_view(frame),
  )
  @tui.draw_list_to_tui_luma(draw_list, auto_render_config())
}

///|
fn add_exposure_sample(
  out : @frontend.LumaBuffer,
  sample : @frontend.LumaBuffer,
  current : @frontend.LumaBuffer,
  weight : Double,
  use_flow : Bool,
) -> Unit {
  if use_flow {
    let flow = @frontend.estimate_optical_flow(sample, current, 4, 1)
    out.add_weighted_sample(
      @frontend.align_with_flow(sample, current, flow),
      weight,
    )
  } else {
    out.add_weighted_sample(sample, weight)
  }
}

///|
fn exposure_mesh_frame(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  use_flow : Bool,
) -> String {
  exposure_mesh_frame_with_view(
    mesh,
    angle_x,
    angle_y,
    angle_z,
    use_flow,
    demo_render_view(),
  )
}

///|
fn exposure_mesh_frame_with_view(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  use_flow : Bool,
  render_view : @frontend.RenderView,
) -> String {
  let viewport = auto_viewport()
  let exposure = @frontend.ExposureSettings::auto(
    @frontend.ShutterSpeed::reciprocal(EXPOSURE_SHUTTER_DENOMINATOR),
    EXPOSURE_FRAME_DT,
  )
  let current = mesh_luma_with_view(
    mesh, angle_x, angle_y, angle_z, render_view,
  )
  let accumulated = @frontend.LumaBuffer::new(viewport.width, viewport.height)
  let sample_count = if exposure.samples > EXPOSURE_ACCUMULATION_SAMPLES {
    exposure.samples
  } else {
    EXPOSURE_ACCUMULATION_SAMPLES
  }
  let weight = 1.0 / sample_count.to_double()
  for i in 0..<sample_count {
    let steps_back = sample_count - 1 - i
    let sample = mesh_luma_with_view(
      mesh,
      angle_x - ANGLE_STEP_X * steps_back.to_double(),
      angle_y - ANGLE_STEP_Y * steps_back.to_double(),
      angle_z - ANGLE_STEP_Z * steps_back.to_double(),
      render_view,
    )
    add_exposure_sample(accumulated, sample, current, weight, use_flow)
  }
  @tui.render_luma_frame(accumulated, auto_render_config())
}

///|
fn exposure_hitchcock_frame(frame : Int, use_flow : Bool) -> String {
  let viewport = auto_viewport()
  let exposure = @frontend.ExposureSettings::auto(
    @frontend.ShutterSpeed::reciprocal(EXPOSURE_SHUTTER_DENOMINATOR),
    EXPOSURE_FRAME_DT,
  )
  let current = hitchcock_luma(frame)
  let accumulated = @frontend.LumaBuffer::new(viewport.width, viewport.height)
  let sample_count = if exposure.samples > EXPOSURE_ACCUMULATION_SAMPLES {
    exposure.samples
  } else {
    EXPOSURE_ACCUMULATION_SAMPLES
  }
  let weight = 1.0 / sample_count.to_double()
  for i in 0..<sample_count {
    let steps_back = sample_count - 1 - i
    let sample_frame = if frame < steps_back { 0 } else { frame - steps_back }
    add_exposure_sample(
      accumulated,
      hitchcock_luma(sample_frame),
      current,
      weight,
      use_flow,
    )
  }
  @tui.render_luma_frame(accumulated, auto_render_config())
}

///|
fn exposure_dolly_frame(frame : Int, use_flow : Bool) -> String {
  let viewport = auto_viewport()
  let exposure = @frontend.ExposureSettings::auto(
    @frontend.ShutterSpeed::reciprocal(EXPOSURE_SHUTTER_DENOMINATOR),
    EXPOSURE_FRAME_DT,
  )
  let current = dolly_luma(frame)
  let accumulated = @frontend.LumaBuffer::new(viewport.width, viewport.height)
  let sample_count = if exposure.samples > EXPOSURE_ACCUMULATION_SAMPLES {
    exposure.samples
  } else {
    EXPOSURE_ACCUMULATION_SAMPLES
  }
  let weight = 1.0 / sample_count.to_double()
  for i in 0..<sample_count {
    let steps_back = sample_count - 1 - i
    let sample_frame = if frame < steps_back { 0 } else { frame - steps_back }
    add_exposure_sample(
      accumulated,
      dolly_luma(sample_frame),
      current,
      weight,
      use_flow,
    )
  }
  @tui.render_luma_frame(accumulated, auto_render_config())
}

///|
fn timeline_mesh_frame(
  mesh : @core.Mesh,
  sample : @frontend.TimelineSample,
) -> String {
  timeline_mesh_frame_with_view(mesh, sample, demo_render_view())
}

///|
fn timeline_mesh_frame_with_view(
  mesh : @core.Mesh,
  sample : @frontend.TimelineSample,
  render_view : @frontend.RenderView,
) -> String {
  let angle_x = sample.time_seconds * 1.5
  let angle_y = sample.time_seconds * 1.05
  let angle_z = sample.time_seconds * 0.6
  mesh_frame_with_view(mesh, angle_x, angle_y, angle_z, render_view)
}

///|
fn timeline_exposure_mesh_frame(
  mesh : @core.Mesh,
  sample : @frontend.TimelineSample,
  use_flow : Bool,
) -> String {
  timeline_exposure_mesh_frame_with_view(
    mesh,
    sample,
    use_flow,
    demo_render_view(),
  )
}

///|
fn timeline_exposure_mesh_frame_with_view(
  mesh : @core.Mesh,
  sample : @frontend.TimelineSample,
  use_flow : Bool,
  render_view : @frontend.RenderView,
) -> String {
  let angle_x = sample.time_seconds * 1.5
  let angle_y = sample.time_seconds * 1.05
  let angle_z = sample.time_seconds * 0.6
  exposure_mesh_frame_with_view(
    mesh, angle_x, angle_y, angle_z, use_flow, render_view,
  )
}

///|
fn render_demo_frame(
  args : Array[String],
  frame_index : Int,
  sample : @frontend.TimelineSample,
) -> String {
  let exposure = has_arg(args, "--long-exposure") ||
    has_arg(args, "--flow-exposure")
  let use_flow = has_arg(args, "--flow-exposure")
  let mesh = demo_mesh(args)
  let render_view = demo_render_view_for_args(args)
  if has_arg(args, "--dolly") {
    if exposure {
      exposure_dolly_frame(frame_index, use_flow)
    } else {
      dolly_frame(frame_index)
    }
  } else if has_arg(args, "--hitchcock") {
    if exposure {
      exposure_hitchcock_frame(frame_index, use_flow)
    } else {
      hitchcock_frame(frame_index)
    }
  } else if exposure {
    timeline_exposure_mesh_frame_with_view(mesh, sample, use_flow, render_view)
  } else {
    timeline_mesh_frame_with_view(mesh, sample, render_view)
  }
}

///|
fn render_demo_sequence(
  args : Array[String],
  timeline : @frontend.Timeline,
) -> @tui.TuiSequence {
  let config = auto_render_config()
  let sequence = @tui.TuiSequence::new(
    config.width,
    config.height,
    timeline.fps,
  )
  for frame_index in 0..<timeline.frame_count() {
    let sample = timeline.sample(frame_index)
    sequence.push_frame(render_demo_frame(args, frame_index, sample))
  }
  sequence
}

///|
fn stream_demo_sequence(
  args : Array[String],
  timeline : @frontend.Timeline,
) -> Unit {
  let config = auto_render_config()
  println("GEOMETRY3D_TUI_SEQUENCE v1")
  println("width=\{config.width}")
  println("height=\{config.height}")
  println("fps=\{timeline.fps}")
  println("frames=\{timeline.frame_count()}")
  for frame_index in 0..<timeline.frame_count() {
    println("---frame---")
    println(render_demo_frame(args, frame_index, timeline.sample(frame_index)))
  }
}

///|
fn render_demo_image(args : Array[String]) -> @tui.TuiImage {
  let config = auto_render_config()
  let exposure = has_arg(args, "--long-exposure") ||
    has_arg(args, "--flow-exposure")
  let use_flow = has_arg(args, "--flow-exposure")
  let render_view = demo_render_view_for_args(args)
  let content = if has_arg(args, "--dolly") {
    if exposure {
      exposure_dolly_frame(1, use_flow)
    } else {
      dolly_frame(0)
    }
  } else if has_arg(args, "--hitchcock") {
    if exposure {
      exposure_hitchcock_frame(1, use_flow)
    } else {
      hitchcock_frame(0)
    }
  } else if exposure {
    exposure_mesh_frame_with_view(
      demo_mesh(args),
      0.2,
      0.3,
      0.0,
      use_flow,
      render_view,
    )
  } else {
    mesh_frame_with_view(demo_mesh(args), 0.2, 0.3, 0.0, render_view)
  }
  @tui.TuiImage::new(config.width, config.height, content)
}

///|
fn frame_interval_ms_for_fps(fps : Int) -> UInt64 {
  if fps >= 60 {
    16UL
  } else if fps >= 30 {
    33UL
  } else if fps >= 24 {
    41UL
  } else if fps >= 12 {
    83UL
  } else {
    100UL
  }
}

///|
fn play_sequence(sequence : @tui.TuiSequence, frame_limit : Int?) -> Unit {
  let interval = frame_interval_ms_for_fps(sequence.fps)
  let mut last_tick = @env.now()
  let mut rendered = 0
  while rendered < sequence.frames.length() {
    let now = @env.now()
    if now - last_tick < interval {
      continue
    }
    last_tick = now
    println("\u{1b}[2J\u{1b}[H\{sequence.frames[rendered].content}")
    rendered += 1
    match frame_limit {
      Some(limit) if rendered >= limit => break
      _ => ()
    }
  }
}

///|
fn record_sequence(args : Array[String], path : String) -> Unit {
  let sequence = render_demo_sequence(args, timeline_from_args(args))
  @fs.write_string_to_file(path, @tui.encode_tui_sequence(sequence)) catch {
    _ => abort("failed to write TUI sequence: " + path)
  }
}

///|
fn play_sequence_file(path : String, frame_limit : Int?) -> Unit {
  let content = @fs.read_file_to_string(path) catch {
    _ => abort("failed to read TUI sequence: " + path)
  }
  play_sequence(@tui.decode_tui_sequence(content), frame_limit)
}

///|
fn export_image(args : Array[String], path : String) -> Unit {
  @fs.write_string_to_file(path, @tui.encode_tui_image(render_demo_image(args))) catch {
    _ => abort("failed to write TUI image: " + path)
  }
}

///|
fn show_image_file(path : String) -> Unit {
  let content = @fs.read_file_to_string(path) catch {
    _ => abort("failed to read TUI image: " + path)
  }
  let image = @tui.decode_tui_image(content)
  println("\u{1b}[2J\u{1b}[H\{image.content}")
}

///|
fn render_once(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
) -> Unit {
  let frame = mesh_frame(mesh, angle_x, angle_y, angle_z)
  println("\u{1b}[2J\u{1b}[H\{frame}")
}

///|
fn render_once_with_view(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  render_view : @frontend.RenderView,
) -> Unit {
  println(
    "\u{1b}[2J\u{1b}[H\{mesh_frame_with_view(mesh, angle_x, angle_y, angle_z, render_view)}",
  )
}

///|
fn render_exposure_once(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  use_flow : Bool,
) -> Unit {
  println(
    "\u{1b}[2J\u{1b}[H\{exposure_mesh_frame(mesh, angle_x, angle_y, angle_z, use_flow)}",
  )
}

///|
fn render_exposure_once_with_view(
  mesh : @core.Mesh,
  angle_x : Double,
  angle_y : Double,
  angle_z : Double,
  use_flow : Bool,
  render_view : @frontend.RenderView,
) -> Unit {
  println(
    "\u{1b}[2J\u{1b}[H\{exposure_mesh_frame_with_view(mesh, angle_x, angle_y, angle_z, use_flow, render_view)}",
  )
}

///|
fn render_hitchcock_once(frame : Int) -> Unit {
  println("\u{1b}[2J\u{1b}[H\{hitchcock_frame(frame)}")
}

///|
fn render_hitchcock_exposure_once(frame : Int, use_flow : Bool) -> Unit {
  println("\u{1b}[2J\u{1b}[H\{exposure_hitchcock_frame(frame, use_flow)}")
}

///|
fn render_dolly_once(frame : Int) -> Unit {
  println("\u{1b}[2J\u{1b}[H\{dolly_frame(frame)}")
}

///|
fn render_dolly_exposure_once(frame : Int, use_flow : Bool) -> Unit {
  println("\u{1b}[2J\u{1b}[H\{exposure_dolly_frame(frame, use_flow)}")
}

///|
fn run_animation(
  mesh : @core.Mesh,
  rotate : Bool,
  frame_limit : Int?,
  exposure : Bool,
  use_flow : Bool,
  render_view : @frontend.RenderView,
) -> Unit {
  let mut angle_x = 0.0
  let mut angle_y = 0.0
  let mut angle_z = 0.0
  let mut last_tick = @env.now()
  let mut rendered = 0
  while true {
    let now = @env.now()
    if now - last_tick < FRAME_INTERVAL_MS {
      continue
    }
    last_tick = now
    if exposure {
      render_exposure_once_with_view(
        mesh, angle_x, angle_y, angle_z, use_flow, render_view,
      )
    } else {
      render_once_with_view(mesh, angle_x, angle_y, angle_z, render_view)
    }
    if rotate {
      angle_x += ANGLE_STEP_X
      angle_y += ANGLE_STEP_Y
      angle_z += ANGLE_STEP_Z
    }
    rendered += 1
    match frame_limit {
      Some(limit) if rendered >= limit => break
      _ => ()
    }
  }
}

///|
fn run_hitchcock(frame_limit : Int?, exposure : Bool, use_flow : Bool) -> Unit {
  let mut last_tick = @env.now()
  let mut rendered = 0
  while true {
    let now = @env.now()
    if now - last_tick < FRAME_INTERVAL_MS {
      continue
    }
    last_tick = now
    if exposure {
      render_hitchcock_exposure_once(rendered, use_flow)
    } else {
      render_hitchcock_once(rendered)
    }
    rendered += 1
    match frame_limit {
      Some(limit) if rendered >= limit => break
      _ => ()
    }
  }
}

///|
fn run_dolly(frame_limit : Int?, exposure : Bool, use_flow : Bool) -> Unit {
  let mut last_tick = @env.now()
  let mut rendered = 0
  while true {
    let now = @env.now()
    if now - last_tick < FRAME_INTERVAL_MS {
      continue
    }
    last_tick = now
    if exposure {
      render_dolly_exposure_once(rendered, use_flow)
    } else {
      render_dolly_once(rendered)
    }
    rendered += 1
    match frame_limit {
      Some(limit) if rendered >= limit => break
      _ => ()
    }
  }
}

///|
fn main {
  let args = @env.args()
  let frame_limit = if has_arg(args, "--once") { Some(1) } else { None }
  let exposure = has_arg(args, "--long-exposure") ||
    has_arg(args, "--flow-exposure")
  let use_flow = has_arg(args, "--flow-exposure")
  let render_view = demo_render_view_for_args(args)
  if has_arg(args, "--record-stdout") {
    stream_demo_sequence(args, timeline_from_args(args))
    return
  }
  match arg_value(args, "--show-image") {
    Some(path) => show_image_file(path)
    None =>
      match arg_value(args, "--export-image") {
        Some(path) => export_image(args, path)
        None =>
          match arg_value(args, "--play") {
            Some(path) => play_sequence_file(path, frame_limit)
            None =>
              match arg_value(args, "--record") {
                Some(path) => record_sequence(args, path)
                None if has_arg(args, "--dolly") =>
                  run_dolly(frame_limit, exposure, use_flow)
                None if has_arg(args, "--hitchcock") =>
                  run_hitchcock(frame_limit, exposure, use_flow)
                None =>
                  run_animation(
                    demo_mesh(args),
                    demo_should_rotate(args),
                    frame_limit,
                    exposure,
                    use_flow,
                    render_view,
                  )
              }
          }
      }
  }
}
