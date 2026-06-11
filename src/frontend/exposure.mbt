pub struct ShutterSpeed {
  seconds : Double
}

pub struct ExposureSettings {
  shutter : ShutterSpeed
  frame_dt : Double
  samples : Int
}

pub fn ShutterSpeed::seconds(seconds : Double) -> ShutterSpeed {
  { seconds: if seconds <= 0.0 { 1.0 / 60.0 } else { seconds } }
}

pub fn ShutterSpeed::reciprocal(denominator : Double) -> ShutterSpeed {
  if denominator <= 0.0 {
    ShutterSpeed::seconds(1.0 / 60.0)
  } else {
    ShutterSpeed::seconds(1.0 / denominator)
  }
}

pub fn ExposureSettings::new(
  shutter : ShutterSpeed,
  frame_dt : Double,
  samples : Int,
) -> ExposureSettings {
  {
    shutter,
    frame_dt: if frame_dt <= 0.0 { 1.0 / 60.0 } else { frame_dt },
    samples: if samples < 1 { 1 } else { samples },
  }
}

pub fn ExposureSettings::auto(
  shutter : ShutterSpeed,
  frame_dt : Double,
) -> ExposureSettings {
  let safe_dt = if frame_dt <= 0.0 { 1.0 / 60.0 } else { frame_dt }
  let count = (shutter.seconds / safe_dt).ceil().to_int()
  ExposureSettings::new(shutter, safe_dt, count)
}
