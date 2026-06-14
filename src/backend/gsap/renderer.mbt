///|
pub struct GsapSvgColor {
  red : Int
  green : Int
  blue : Int
}

///|
pub struct GsapSvgRenderConfig {
  width : Int
  height : Int
  background_color : GsapSvgColor
  foreground_color : GsapSvgColor
  shade_levels : Int
}

///|
priv struct OrderedTriangle {
  triangle : @frontend.DrawTriangle
  source_index : Int
  average_depth : Double
}

///|
pub fn GsapSvgColor::rgb(red : Int, green : Int, blue : Int) -> GsapSvgColor {
  {
    red: clamp_channel(red),
    green: clamp_channel(green),
    blue: clamp_channel(blue),
  }
}

///|
pub fn GsapSvgRenderConfig::default() -> GsapSvgRenderConfig {
  GsapSvgRenderConfig::sized(640, 480)
}

///|
pub fn GsapSvgRenderConfig::sized(
  width : Int,
  height : Int,
) -> GsapSvgRenderConfig {
  {
    width: if width > 0 {
      width
    } else {
      640
    },
    height: if height > 0 {
      height
    } else {
      480
    },
    background_color: GsapSvgColor::rgb(7, 12, 22),
    foreground_color: GsapSvgColor::rgb(112, 226, 255),
    shade_levels: 256,
  }
}

///|
fn clamp_channel(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn clamp01(value : Double) -> Double {
  if value < 0.0 {
    0.0
  } else if value > 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn normalized_shade_levels(levels : Int) -> Int {
  if levels < 2 {
    2
  } else if levels > 256 {
    256
  } else {
    levels
  }
}

///|
fn normalized_config(config : GsapSvgRenderConfig) -> GsapSvgRenderConfig {
  {
    width: if config.width > 0 {
      config.width
    } else {
      640
    },
    height: if config.height > 0 {
      config.height
    } else {
      480
    },
    background_color: GsapSvgColor::rgb(
      config.background_color.red,
      config.background_color.green,
      config.background_color.blue,
    ),
    foreground_color: GsapSvgColor::rgb(
      config.foreground_color.red,
      config.foreground_color.green,
      config.foreground_color.blue,
    ),
    shade_levels: normalized_shade_levels(config.shade_levels),
  }
}

///|
fn color_css(color : GsapSvgColor) -> String {
  "rgb(\{color.red}, \{color.green}, \{color.blue})"
}

///|
fn shade_css(color : GsapSvgColor, intensity : Double, levels : Int) -> String {
  let last = normalized_shade_levels(levels) - 1
  let shade = (clamp01(intensity) * last.to_double()).round().to_int()
  let scale = shade.to_double() / last.to_double()
  color_css(
    GsapSvgColor::rgb(
      (color.red.to_double() * scale).round().to_int(),
      (color.green.to_double() * scale).round().to_int(),
      (color.blue.to_double() * scale).round().to_int(),
    ),
  )
}

///|
fn triangle_points(triangle : @frontend.DrawTriangle) -> String {
  "\{triangle.p0.x},\{triangle.p0.y} \{triangle.p1.x},\{triangle.p1.y} \{triangle.p2.x},\{triangle.p2.y}"
}

///|
fn triangle_average_depth(triangle : @frontend.DrawTriangle) -> Double {
  (triangle.p0.depth + triangle.p1.depth + triangle.p2.depth) / 3.0
}

///|
fn ordered_triangles(draw_list : @frontend.DrawList) -> Array[OrderedTriangle] {
  let ordered = draw_list.triangles.mapi(fn(index, triangle) {
    {
      triangle,
      source_index: index,
      average_depth: triangle_average_depth(triangle),
    }
  })
  ordered.sort_by(fn(a, b) {
    if a.average_depth > b.average_depth {
      -1
    } else if a.average_depth < b.average_depth {
      1
    } else {
      a.source_index - b.source_index
    }
  })
  ordered
}

///|
extern "js" fn update_svg_dom(
  svg : @dom.Element,
  width : Int,
  height : Int,
  background : String,
  points : Array[String],
  fills : Array[String],
) -> Unit =
  #| (svg, width, height, background, points, fills) => {
  #|   const namespace = "http://www.w3.org/2000/svg";
  #|   svg.setAttribute("width", String(width));
  #|   svg.setAttribute("height", String(height));
  #|   svg.setAttribute("viewBox", `0 0 ${width} ${height}`);
  #|   svg.setAttribute("role", "img");
  #|   svg.setAttribute("data-geometry3d-backend", "gsap-svg");
  #|   let backgroundNode = svg.querySelector(":scope > [data-gsap-svg-background]");
  #|   let triangleRoot = svg.querySelector(":scope > [data-gsap-svg-triangles]");
  #|   if (!backgroundNode || !triangleRoot) {
  #|     svg.replaceChildren();
  #|     backgroundNode = document.createElementNS(namespace, "rect");
  #|     backgroundNode.setAttribute("data-gsap-svg-background", "");
  #|     triangleRoot = document.createElementNS(namespace, "g");
  #|     triangleRoot.setAttribute("data-gsap-svg-triangles", "");
  #|     svg.append(backgroundNode, triangleRoot);
  #|   }
  #|   backgroundNode.setAttribute("width", String(width));
  #|   backgroundNode.setAttribute("height", String(height));
  #|   backgroundNode.setAttribute("fill", background);
  #|   while (triangleRoot.children.length < points.length) {
  #|     const polygon = document.createElementNS(namespace, "polygon");
  #|     polygon.setAttribute("vector-effect", "non-scaling-stroke");
  #|     triangleRoot.appendChild(polygon);
  #|   }
  #|   while (triangleRoot.children.length > points.length) {
  #|     triangleRoot.lastElementChild.remove();
  #|   }
  #|   for (let i = 0; i < points.length; i += 1) {
  #|     const polygon = triangleRoot.children[i];
  #|     polygon.setAttribute("points", points[i]);
  #|     polygon.setAttribute("fill", fills[i]);
  #|   }
  #| }

///|
pub fn render_draw_list(
  svg : @dom.Element,
  draw_list : @frontend.DrawList,
  config : GsapSvgRenderConfig,
) -> Unit {
  let config = normalized_config(config)
  let ordered = ordered_triangles(draw_list)
  let points = ordered.map(fn(item) { triangle_points(item.triangle) })
  let fills = ordered.map(fn(item) {
    shade_css(
      config.foreground_color,
      item.triangle.intensity,
      config.shade_levels,
    )
  })
  update_svg_dom(
    svg,
    config.width,
    config.height,
    color_css(config.background_color),
    points,
    fills,
  )
}

///|
pub fn render_scene(
  svg : @dom.Element,
  scene : @frontend.Scene,
  render_view : @frontend.RenderView,
  config : GsapSvgRenderConfig,
) -> Unit {
  render_draw_list(svg, @frontend.build_draw_list(scene, render_view), config)
}
