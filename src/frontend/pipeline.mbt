pub struct RenderView {
  camera : @view.Camera3
  projection : @view.PerspectiveProjection
}

using @arith { trait Sqrt }
using @lg { trait Num }

const SHADOW_MAP_SIZE : Int = 128
const SHADOW_PADDING_RATIO : Double = 0.05
const SHADOW_MIN_PADDING : Double = 0.25
const SHADOW_BIAS_RATIO : Double = 0.005
const SHADOW_MIN_BIAS : Double = 1.0e-4
const SHADOW_AMBIENT_VISIBILITY : Double = 0.35

priv struct ShadowMap {
  light_camera : @view.Camera3
  min_x : Double
  max_x : Double
  min_y : Double
  max_y : Double
  width : Int
  height : Int
  depths : Array[Double]
  bias : Double
}

fn shadow_edge_function(
  ax : Double,
  ay : Double,
  bx : Double,
  by : Double,
  px : Double,
  py : Double,
) -> Double {
  (px - ax) * (by - ay) - (py - ay) * (bx - ax)
}

fn shadow_index(shadow_map : ShadowMap, x : Int, y : Int) -> Int {
  y * shadow_map.width + x
}

fn shadow_padding(span : Double) -> Double {
  let scaled = span * SHADOW_PADDING_RATIO
  if scaled > SHADOW_MIN_PADDING { scaled } else { SHADOW_MIN_PADDING }
}

fn choose_light_up(light_direction : @la.Vector[Double]) -> @la.Vector[Double] {
  let world_up = @core.vec3(0.0, 1.0, 0.0)
  let alignment = light_direction.dot(world_up)
  let abs_alignment = Num::abs(alignment)
  if abs_alignment > 0.99 {
    @core.vec3(0.0, 0.0, 1.0)
  } else {
    world_up
  }
}

fn scene_center_and_radius(world_meshes : Array[@core.Mesh]) -> (@la.Vector[Double], Double) {
  let mut min_x = 1.0e30
  let mut min_y = 1.0e30
  let mut min_z = 1.0e30
  let mut max_x = -1.0e30
  let mut max_y = -1.0e30
  let mut max_z = -1.0e30
  let mut has_vertex = false

  for mesh in world_meshes {
    for vertex in mesh.vertices {
      has_vertex = true
      if vertex[0] < min_x { min_x = vertex[0] }
      if vertex[1] < min_y { min_y = vertex[1] }
      if vertex[2] < min_z { min_z = vertex[2] }
      if vertex[0] > max_x { max_x = vertex[0] }
      if vertex[1] > max_y { max_y = vertex[1] }
      if vertex[2] > max_z { max_z = vertex[2] }
    }
  }

  if !has_vertex {
    return (@core.vec3(0.0, 0.0, 0.0), 1.0)
  }

  let center = @core.vec3(
    (min_x + max_x) * 0.5,
    (min_y + max_y) * 0.5,
    (min_z + max_z) * 0.5,
  )
  let mut radius = 1.0
  for mesh in world_meshes {
    for vertex in mesh.vertices {
      let offset = @core.sub_vec(vertex, center)
      let distance = Sqrt::sqrt(offset.dot(offset))
      if distance > radius {
        radius = distance
      }
    }
  }
  (center, radius)
}

fn make_light_camera(
  world_meshes : Array[@core.Mesh],
  light_direction : @la.Vector[Double],
) -> @view.Camera3 {
  let (center, radius) = scene_center_and_radius(world_meshes)
  let eye = center + light_direction.right_scale(radius * 2.0 + 1.0)
  @view.Camera3::look_at(eye, center, choose_light_up(light_direction))
}

fn light_space_bounds(
  world_meshes : Array[@core.Mesh],
  light_camera : @view.Camera3,
) -> (Double, Double, Double, Double, Double) {
  let mut min_x = 1.0e30
  let mut min_y = 1.0e30
  let mut min_z = 1.0e30
  let mut max_x = -1.0e30
  let mut max_y = -1.0e30
  let mut max_z = -1.0e30
  let mut has_vertex = false

  for mesh in world_meshes {
    for vertex in mesh.vertices {
      has_vertex = true
      let point = light_camera.world_to_camera_point(vertex)
      if point[0] < min_x { min_x = point[0] }
      if point[1] < min_y { min_y = point[1] }
      if point[2] < min_z { min_z = point[2] }
      if point[0] > max_x { max_x = point[0] }
      if point[1] > max_y { max_y = point[1] }
      if point[2] > max_z { max_z = point[2] }
    }
  }

  if !has_vertex {
    return (-1.0, 1.0, -1.0, 1.0, 1.0)
  }

  let pad_x = shadow_padding(max_x - min_x)
  let pad_y = shadow_padding(max_y - min_y)
  let depth_span = max_z - min_z
  (
    min_x - pad_x,
    max_x + pad_x,
    min_y - pad_y,
    max_y + pad_y,
    if depth_span > @core.DEPTH_EPSILON { depth_span } else { 1.0 },
  )
}

fn project_shadow_x(shadow_map : ShadowMap, x : Double) -> Double {
  let span = shadow_map.max_x - shadow_map.min_x
  if span.abs() <= @core.DEPTH_EPSILON {
    shadow_map.width.to_double() * 0.5
  } else {
    (x - shadow_map.min_x) / span * (shadow_map.width - 1).to_double()
  }
}

fn project_shadow_y(shadow_map : ShadowMap, y : Double) -> Double {
  let span = shadow_map.max_y - shadow_map.min_y
  if span.abs() <= @core.DEPTH_EPSILON {
    shadow_map.height.to_double() * 0.5
  } else {
    (shadow_map.max_y - y) / span * (shadow_map.height - 1).to_double()
  }
}

fn rasterize_shadow_triangle(
  shadow_map : ShadowMap,
  p0 : @view.ProjectedVertex,
  p1 : @view.ProjectedVertex,
  p2 : @view.ProjectedVertex,
) -> Unit {
  let area = shadow_edge_function(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y)
  if area.abs() <= @core.DEPTH_EPSILON {
    return
  }
  let min_x = @core.min3(p0.x, p1.x, p2.x).floor().to_int()
  let max_x = @core.max3(p0.x, p1.x, p2.x).ceil().to_int()
  let min_y = @core.min3(p0.y, p1.y, p2.y).floor().to_int()
  let max_y = @core.max3(p0.y, p1.y, p2.y).ceil().to_int()
  for y in min_y..<(max_y + 1) {
    for x in min_x..<(max_x + 1) {
      let sample_x = x.to_double() + 0.5
      let sample_y = y.to_double() + 0.5
      let w0 = shadow_edge_function(p1.x, p1.y, p2.x, p2.y, sample_x, sample_y)
      let w1 = shadow_edge_function(p2.x, p2.y, p0.x, p0.y, sample_x, sample_y)
      let w2 = shadow_edge_function(p0.x, p0.y, p1.x, p1.y, sample_x, sample_y)
      let inside = if area > 0.0 {
        w0 >= 0.0 && w1 >= 0.0 && w2 >= 0.0
      } else {
        w0 <= 0.0 && w1 <= 0.0 && w2 <= 0.0
      }
      if inside && x >= 0 && x < shadow_map.width && y >= 0 && y < shadow_map.height {
        let inv_area = 1.0 / area
        let depth =
          (w0 * inv_area) * p0.depth +
          (w1 * inv_area) * p1.depth +
          (w2 * inv_area) * p2.depth
        let index = shadow_index(shadow_map, x, y)
        if depth + @core.DEPTH_EPSILON < shadow_map.depths[index] {
          shadow_map.depths[index] = depth
        }
      }
    }
  }
}

fn build_shadow_map(world_meshes : Array[@core.Mesh], light : Light) -> ShadowMap {
  let light_camera = make_light_camera(world_meshes, light.direction)
  let (min_x, max_x, min_y, max_y, depth_span) = light_space_bounds(world_meshes, light_camera)
  let shadow_map = {
    light_camera,
    min_x,
    max_x,
    min_y,
    max_y,
    width: SHADOW_MAP_SIZE,
    height: SHADOW_MAP_SIZE,
    depths: Array::make(SHADOW_MAP_SIZE * SHADOW_MAP_SIZE, LUMA_FAR_DEPTH),
    bias: if depth_span * SHADOW_BIAS_RATIO > SHADOW_MIN_BIAS {
      depth_span * SHADOW_BIAS_RATIO
    } else {
      SHADOW_MIN_BIAS
    },
  }

  for mesh in world_meshes {
    let light_vertices = mesh.vertices.map(fn(vertex) {
      let point = light_camera.world_to_camera_point(vertex)
      @view.ProjectedVertex::new(
        project_shadow_x(shadow_map, point[0]),
        project_shadow_y(shadow_map, point[1]),
        point[2],
      )
    })
    for face in mesh.faces {
      for triangle in @core.triangulate_quad(face) {
        rasterize_shadow_triangle(
          shadow_map,
          light_vertices[triangle.a],
          light_vertices[triangle.b],
          light_vertices[triangle.c],
        )
      }
    }
  }

  shadow_map
}

fn sample_shadow_visibility(
  shadow_map : ShadowMap,
  world_point : @la.Vector[Double],
  light_direction : @la.Vector[Double],
) -> Double {
  let sample_point = world_point + light_direction.right_scale(shadow_map.bias * 2.0)
  let light_point = shadow_map.light_camera.world_to_camera_point(sample_point)
  let px = project_shadow_x(shadow_map, light_point[0]).round().to_int()
  let py = project_shadow_y(shadow_map, light_point[1]).round().to_int()
  if px < 0 || px >= shadow_map.width || py < 0 || py >= shadow_map.height {
    return 1.0
  }
  let stored = shadow_map.depths[shadow_index(shadow_map, px, py)]
  if stored >= LUMA_FAR_DEPTH * 0.5 {
    1.0
  } else if light_point[2] <= stored + shadow_map.bias {
    1.0
  } else {
    0.0
  }
}

fn face_shadow_visibility(
  shadow_map : ShadowMap,
  vertices : Array[@la.Vector[Double]],
  face : @core.QuadFace,
  light_direction : @la.Vector[Double],
) -> Double {
  let samples = [
    vertices[face.a],
    vertices[face.b],
    vertices[face.c],
    vertices[face.d],
  ]
  let mut total = sample_shadow_visibility(
    shadow_map,
    @core.face_center(vertices, face),
    light_direction,
  )
  for sample in samples {
    total += sample_shadow_visibility(shadow_map, sample, light_direction)
  }
  total / (samples.length() + 1).to_double()
}

pub fn RenderView::perspective(
  camera : @view.Camera3,
  projection : @view.PerspectiveProjection,
) -> RenderView {
  { camera, projection }
}

pub fn RenderView::scientific(
  camera : @view.ScientificCamera,
  viewport : @view.Viewport,
) -> RenderView {
  {
    camera: camera.camera,
    projection: camera.to_perspective_projection(viewport),
  }
}

pub fn build_draw_list(scene : Scene, render_view : RenderView) -> DrawList {
  let draw_list = DrawList::new()
  let camera_position = @core.vec3(0.0, 0.0, 0.0)
  let world_meshes = scene.objects.map(fn(object) { object.transform.apply_mesh(object.mesh) })
  let shadow_map = build_shadow_map(world_meshes, scene.light)
  let camera_light = render_view.camera.world_to_camera_direction(scene.light.direction)
  let light_direction = @core.normalize_vec(camera_light)

  for world_mesh in world_meshes {
    let camera_vertices = world_mesh.vertices.map(fn(vertex) {
      render_view.camera.world_to_camera_point(vertex)
    })
    let projected = @view.project_perspective_vertices(camera_vertices, render_view.projection)

    for face in world_mesh.faces {
      if @core.face_is_visible(camera_vertices, face, camera_position) {
        let base_intensity = @core.face_intensity(camera_vertices, face, light_direction)
        let shadow_visibility = if base_intensity <= 0.0 {
          0.0
        } else {
          let occlusion = face_shadow_visibility(
            shadow_map,
            world_mesh.vertices,
            face,
            scene.light.direction,
          )
          SHADOW_AMBIENT_VISIBILITY + (1.0 - SHADOW_AMBIENT_VISIBILITY) * occlusion
        }
        let intensity = base_intensity * shadow_visibility
        for triangle in @core.triangulate_quad(face) {
          draw_list.push_triangle(DrawTriangle::new(
            projected[triangle.a],
            projected[triangle.b],
            projected[triangle.c],
            intensity,
          ))
        }
      }
    }
  }

  draw_list
}
