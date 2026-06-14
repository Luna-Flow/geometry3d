///|
#external
type GsapTimeline

///|
pub struct GsapPlayer {
  timeline : GsapTimeline
  duration_seconds : Double
}

///|
extern "js" fn create_timeline(
  duration_seconds : Double,
  on_frame : (Double) -> Unit,
  repeat : Int,
) -> GsapTimeline =
  #| (duration, onFrame, repeat) => {
  #|   const gsap = globalThis.gsap;
  #|   if (!gsap || typeof gsap.timeline !== "function") {
  #|     throw new Error("geometry3d GSAP backend requires globalThis.gsap");
  #|   }
  #|   const clock = { time: 0 };
  #|   const timeline = gsap.timeline({ paused: true, repeat });
  #|   timeline.to(clock, {
  #|     time: duration,
  #|     duration,
  #|     ease: "none",
  #|     onUpdate: () => onFrame(clock.time),
  #|   }, 0);
  #|   onFrame(0);
  #|   return timeline;
  #| }

///|
extern "js" fn timeline_play(timeline : GsapTimeline) -> Unit = "timeline => timeline.play()"

///|
extern "js" fn timeline_pause(timeline : GsapTimeline) -> Unit = "timeline => timeline.pause()"

///|
extern "js" fn timeline_reverse(timeline : GsapTimeline) -> Unit = "timeline => timeline.reverse()"

///|
extern "js" fn timeline_restart(timeline : GsapTimeline) -> Unit = "timeline => timeline.restart()"

///|
extern "js" fn timeline_seek(timeline : GsapTimeline, time : Double) -> Unit = "(timeline, time) => timeline.time(time)"

///|
extern "js" fn timeline_progress(timeline : GsapTimeline) -> Double = "timeline => timeline.progress()"

///|
extern "js" fn timeline_set_progress(
  timeline : GsapTimeline,
  progress : Double,
) -> Unit = "(timeline, progress) => timeline.progress(progress)"

///|
extern "js" fn timeline_time(timeline : GsapTimeline) -> Double = "timeline => timeline.time()"

///|
extern "js" fn timeline_time_scale(timeline : GsapTimeline) -> Double = "timeline => timeline.timeScale()"

///|
extern "js" fn timeline_set_time_scale(
  timeline : GsapTimeline,
  scale : Double,
) -> Unit = "(timeline, scale) => timeline.timeScale(scale)"

///|
extern "js" fn timeline_set_repeat(
  timeline : GsapTimeline,
  repeat : Int,
) -> Unit = "(timeline, repeat) => timeline.repeat(repeat)"

///|
extern "js" fn timeline_is_paused(timeline : GsapTimeline) -> Bool = "timeline => timeline.paused()"

///|
extern "js" fn timeline_kill(timeline : GsapTimeline) -> Unit = "timeline => timeline.kill()"

///|
pub fn GsapPlayer::new(
  duration_seconds : Double,
  on_frame : (Double) -> Unit,
  repeat? : Int = -1,
) -> GsapPlayer {
  let duration = if duration_seconds > 0.0 { duration_seconds } else { 1.0 }
  {
    timeline: create_timeline(duration, on_frame, repeat),
    duration_seconds: duration,
  }
}

///|
pub fn GsapPlayer::play(self : GsapPlayer) -> Unit {
  timeline_play(self.timeline)
}

///|
pub fn GsapPlayer::pause(self : GsapPlayer) -> Unit {
  timeline_pause(self.timeline)
}

///|
pub fn GsapPlayer::reverse(self : GsapPlayer) -> Unit {
  timeline_reverse(self.timeline)
}

///|
pub fn GsapPlayer::restart(self : GsapPlayer) -> Unit {
  timeline_restart(self.timeline)
}

///|
pub fn GsapPlayer::seek(self : GsapPlayer, time_seconds : Double) -> Unit {
  let time = if time_seconds < 0.0 {
    0.0
  } else if time_seconds > self.duration_seconds {
    self.duration_seconds
  } else {
    time_seconds
  }
  timeline_seek(self.timeline, time)
}

///|
pub fn GsapPlayer::progress(self : GsapPlayer) -> Double {
  timeline_progress(self.timeline)
}

///|
pub fn GsapPlayer::set_progress(self : GsapPlayer, progress : Double) -> Unit {
  timeline_set_progress(
    self.timeline,
    if progress < 0.0 {
      0.0
    } else if progress > 1.0 {
      1.0
    } else {
      progress
    },
  )
}

///|
pub fn GsapPlayer::time(self : GsapPlayer) -> Double {
  timeline_time(self.timeline)
}

///|
pub fn GsapPlayer::time_scale(self : GsapPlayer) -> Double {
  timeline_time_scale(self.timeline)
}

///|
pub fn GsapPlayer::set_time_scale(self : GsapPlayer, scale : Double) -> Unit {
  timeline_set_time_scale(self.timeline, if scale > 0.0 { scale } else { 1.0 })
}

///|
pub fn GsapPlayer::set_repeat(self : GsapPlayer, repeat : Int) -> Unit {
  timeline_set_repeat(self.timeline, if repeat < -1 { -1 } else { repeat })
}

///|
pub fn GsapPlayer::is_paused(self : GsapPlayer) -> Bool {
  timeline_is_paused(self.timeline)
}

///|
pub fn GsapPlayer::kill(self : GsapPlayer) -> Unit {
  timeline_kill(self.timeline)
}
