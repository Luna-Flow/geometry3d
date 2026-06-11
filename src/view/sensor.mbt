pub struct SensorSpec {
  width_mm : Double
  height_mm : Double
}

pub fn SensorSpec::custom(width_mm : Double, height_mm : Double) -> SensorSpec {
  {
    width_mm: if width_mm <= 0.0 { 1.0 } else { width_mm },
    height_mm: if height_mm <= 0.0 { 1.0 } else { height_mm },
  }
}

pub fn SensorSpec::apsc() -> SensorSpec {
  SensorSpec::custom(23.5, 15.6)
}

pub fn SensorSpec::full_frame() -> SensorSpec {
  SensorSpec::custom(36.0, 24.0)
}

pub fn SensorSpec::medium_format() -> SensorSpec {
  SensorSpec::custom(44.0, 33.0)
}

pub fn SensorSpec::diagonal_mm(self : SensorSpec) -> Double {
  (self.width_mm * self.width_mm + self.height_mm * self.height_mm).sqrt()
}
