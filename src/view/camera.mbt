pub struct Camera3 {
  eye : @la.Vector[Double]
  target : @la.Vector[Double]
  up : @la.Vector[Double]
}

pub fn Camera3::look_at(
  eye : @la.Vector[Double],
  target : @la.Vector[Double],
  up : @la.Vector[Double],
) -> Camera3 {
  { eye, target, up }
}

pub fn Camera3::default(distance : Double) -> Camera3 {
  Camera3::look_at(
    @core.vec3(0.0, 0.0, -distance),
    @core.vec3(0.0, 0.0, 0.0),
    @core.vec3(0.0, 1.0, 0.0),
  )
}

pub fn Camera3::forward(self : Camera3) -> @la.Vector[Double] {
  @core.normalize_vec(@core.sub_vec(self.target, self.eye))
}

pub fn Camera3::right(self : Camera3) -> @la.Vector[Double] {
  @core.normalize_vec(@core.cross_vec(self.up, self.forward()))
}

pub fn Camera3::true_up(self : Camera3) -> @la.Vector[Double] {
  @core.normalize_vec(@core.cross_vec(self.forward(), self.right()))
}

pub fn Camera3::view_transform(self : Camera3) -> @core.Transform3 {
  let right = self.right()
  let up = self.true_up()
  let forward = self.forward()
  @core.Transform3::from_matrix(
    @la.Matrix::from_2d_array([
      [right[0], right[1], right[2], -right.dot(self.eye)],
      [up[0], up[1], up[2], -up.dot(self.eye)],
      [forward[0], forward[1], forward[2], -forward.dot(self.eye)],
      [0.0, 0.0, 0.0, 1.0],
    ]),
  )
}

pub fn Camera3::world_to_camera_point(
  self : Camera3,
  point : @la.Vector[Double],
) -> @la.Vector[Double] {
  self.view_transform().apply_point(point)
}

pub fn Camera3::world_to_camera_direction(
  self : Camera3,
  direction : @la.Vector[Double],
) -> @la.Vector[Double] {
  self.view_transform().apply_direction(direction)
}
