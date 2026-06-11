const FRAME_INTERVAL_MS : UInt64 = 33UL
const ANGLE_STEP_X : Double = 0.05
const ANGLE_STEP_Y : Double = 0.035
const ANGLE_STEP_Z : Double = 0.02

fn demo_mesh(args : Array[String]) -> Mesh {
  if args.iter().any(fn(arg) { arg == "--sphere" }) {
    sphere_mesh(2.4, 18, 36)
  } else {
    cube_mesh(1.0)
  }
}

fn demo_should_rotate(args : Array[String]) -> Bool {
  !args.iter().any(fn(arg) { arg == "--sphere" })
}

fn mesh_frame(mesh : Mesh, angle_x : Double, angle_y : Double, angle_z : Double) -> String {
  let transform = Transform3::rotation(angle_x, angle_y, angle_z)
  render_frame(mesh, transform, TuiRenderConfig::default())
}

fn render_once(mesh : Mesh, angle_x : Double, angle_y : Double, angle_z : Double) -> Unit {
  let frame = mesh_frame(mesh, angle_x, angle_y, angle_z)
  println("\u{1b}[2J\u{1b}[H\{frame}")
}

fn run_animation(mesh : Mesh, rotate : Bool, frame_limit : Int?) -> Unit {
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
    render_once(mesh, angle_x, angle_y, angle_z)
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

fn main {
  let args = @env.args()
  let mesh = demo_mesh(args)
  let rotate = demo_should_rotate(args)
  if args.iter().any(fn(arg) { arg == "--once" }) {
    run_animation(mesh, rotate, Some(1))
  } else {
    run_animation(mesh, rotate, None)
  }
}
