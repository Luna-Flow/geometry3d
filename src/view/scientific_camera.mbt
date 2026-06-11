pub struct WorldUnit {
  meters_per_unit : Double
}

pub struct ScientificCamera {
  camera : Camera3
  sensor : SensorSpec
  lens : LensSpec
  world_unit : WorldUnit
}

pub fn WorldUnit::new(meters_per_unit : Double) -> WorldUnit {
  { meters_per_unit: if meters_per_unit <= 0.0 { 1.0 } else { meters_per_unit } }
}

pub fn WorldUnit::unitless() -> WorldUnit {
  WorldUnit::new(1.0)
}

pub fn WorldUnit::millimeters_per_unit(self : WorldUnit) -> Double {
  self.meters_per_unit * 1000.0
}

pub fn ScientificCamera::new(
  camera : Camera3,
  sensor : SensorSpec,
  lens : LensSpec,
  world_unit : WorldUnit,
) -> ScientificCamera {
  { camera, sensor, lens, world_unit }
}

pub fn ScientificCamera::auto(viewport : Viewport) -> ScientificCamera {
  ignore(viewport)
  ScientificCamera::new(
    Camera3::default(4.5),
    SensorSpec::full_frame(),
    LensSpec::normal_full_frame(),
    WorldUnit::unitless(),
  )
}

pub fn ScientificCamera::with_camera(self : ScientificCamera, camera : Camera3) -> ScientificCamera {
  { camera, sensor: self.sensor, lens: self.lens, world_unit: self.world_unit }
}

pub fn ScientificCamera::with_lens(self : ScientificCamera, lens : LensSpec) -> ScientificCamera {
  { camera: self.camera, sensor: self.sensor, lens, world_unit: self.world_unit }
}

pub fn ScientificCamera::focal_length_world_units(self : ScientificCamera) -> Double {
  self.lens.focal_length_mm / self.world_unit.millimeters_per_unit()
}

pub fn ScientificCamera::sensor_height_world_units(self : ScientificCamera) -> Double {
  self.sensor.height_mm / self.world_unit.millimeters_per_unit()
}

pub fn ScientificCamera::projection_scale(self : ScientificCamera, viewport : Viewport) -> Double {
  viewport.height.to_double() * self.lens.focal_length_mm / self.sensor.height_mm
}

pub fn ScientificCamera::to_perspective_projection(
  self : ScientificCamera,
  viewport : Viewport,
) -> PerspectiveProjection {
  PerspectiveProjection::new(viewport, self.projection_scale(viewport))
}
