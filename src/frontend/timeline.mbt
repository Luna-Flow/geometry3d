///|
pub struct Timeline {
  duration_seconds : Double
  fps : Int
}

///|
pub struct TimelineSample {
  frame_index : Int
  time_seconds : Double
  progress : Double
}

///|
pub struct ScalarKeyframe {
  time_seconds : Double
  value : Double
}

///|
pub struct ScalarTrack {
  keyframes : Array[ScalarKeyframe]
}

///|
pub fn Timeline::new(duration_seconds : Double, fps : Int) -> Timeline {
  {
    duration_seconds: if duration_seconds <= 0.0 {
      1.0
    } else {
      duration_seconds
    },
    fps: if fps < 1 {
      1
    } else {
      fps
    },
  }
}

///|
pub fn Timeline::frame_count(self : Timeline) -> Int {
  let count = (self.duration_seconds * self.fps.to_double()).ceil().to_int()
  if count < 1 {
    1
  } else {
    count
  }
}

///|
pub fn Timeline::frame_dt(self : Timeline) -> Double {
  1.0 / self.fps.to_double()
}

///|
pub fn Timeline::sample(self : Timeline, frame_index : Int) -> TimelineSample {
  let safe_index = if frame_index < 0 { 0 } else { frame_index }
  let time = safe_index.to_double() * self.frame_dt()
  {
    frame_index: safe_index,
    time_seconds: time,
    progress: if self.duration_seconds <= 0.0 {
      0.0
    } else if time >= self.duration_seconds {
      1.0
    } else {
      time / self.duration_seconds
    },
  }
}

///|
pub fn ScalarKeyframe::new(
  time_seconds : Double,
  value : Double,
) -> ScalarKeyframe {
  { time_seconds, value }
}

///|
pub fn ScalarTrack::new(keyframes : Array[ScalarKeyframe]) -> ScalarTrack {
  { keyframes, }
}

///|
fn lerp(a : Double, b : Double, t : Double) -> Double {
  a + (b - a) * t
}

///|
pub fn ScalarTrack::sample(self : ScalarTrack, time_seconds : Double) -> Double {
  if self.keyframes.length() == 0 {
    return 0.0
  }
  if self.keyframes.length() == 1 ||
    time_seconds <= self.keyframes[0].time_seconds {
    return self.keyframes[0].value
  }
  for i in 0..<(self.keyframes.length() - 1) {
    let a = self.keyframes[i]
    let b = self.keyframes[i + 1]
    if time_seconds <= b.time_seconds {
      let span = b.time_seconds - a.time_seconds
      if span <= @core.DEPTH_EPSILON {
        return b.value
      }
      return lerp(a.value, b.value, (time_seconds - a.time_seconds) / span)
    }
  }
  self.keyframes[self.keyframes.length() - 1].value
}
