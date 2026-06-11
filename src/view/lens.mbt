pub struct LensSpec {
  focal_length_mm : Double
}

pub fn LensSpec::new(focal_length_mm : Double) -> LensSpec {
  { focal_length_mm: if focal_length_mm <= 0.0 { 1.0 } else { focal_length_mm } }
}

pub fn LensSpec::normal_full_frame() -> LensSpec {
  LensSpec::new(50.0)
}

fn fov_for_dimension(sensor_dimension_mm : Double, focal_length_mm : Double) -> Double {
  2.0 * @math.atan(sensor_dimension_mm / (2.0 * focal_length_mm))
}

pub fn LensSpec::horizontal_fov(self : LensSpec, sensor : SensorSpec) -> Double {
  fov_for_dimension(sensor.width_mm, self.focal_length_mm)
}

pub fn LensSpec::vertical_fov(self : LensSpec, sensor : SensorSpec) -> Double {
  fov_for_dimension(sensor.height_mm, self.focal_length_mm)
}

pub fn LensSpec::diagonal_fov(self : LensSpec, sensor : SensorSpec) -> Double {
  fov_for_dimension(sensor.diagonal_mm(), self.focal_length_mm)
}
