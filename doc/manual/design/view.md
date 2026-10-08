# view design

## Design goal

`view` answers one question: where on the screen does a world-space point appear, and how far away is it? The answer must be exact enough that every backend (terminal cells, canvas pixels, SVG polygons) shows the same picture, simple enough to state in three formulas, and parameterized the way a photographer thinks: a sensor, a lens and a distance, rather than an abstract field-of-view number.

## Constraints

- The projection must give the same picture on terminal cells, canvas pixels and SVG coordinates, so it works in viewport units and leaves the cell shape to the backends.
- There is no clipper anywhere in the pipeline, so every projected point is assumed to lie in front of the camera.
- Depth must stay comparable between triangles drawn by different rasterizers.

## Mathematical background

The pipeline has three stages, each a map between coordinate systems:

$$
\underbrace{p_{\text{world}}}_{\texttt{core}}
\xrightarrow{\ V\ }
\underbrace{p_{\text{camera}}}_{x \text{ right},\ y \text{ up},\ z \text{ forward}}
\xrightarrow{\ \text{project}\ }
\underbrace{(x_s, y_s)}_{\text{viewport units}},\ \mathit{depth} = z .
$$

### The camera frame

`Camera3` is given by an eye $e$, a target $t$ and an approximate up vector $a$. It derives

$$
f = \frac{t - e}{\lVert t - e \rVert},\qquad
r = \frac{a \times f}{\lVert a \times f \rVert},\qquad
u = f \times r .
$$

These three vectors form an orthonormal frame. $r$ is perpendicular to $f$ by construction of the cross product, and $u = f \times r$ is perpendicular to both; $\lVert u \rVert = \lVert f \rVert \lVert r \rVert \sin 90° = 1$, so the final normalization in the code changes nothing but rounding. The triple product gives the orientation:

$$
r \times u = r \times (f \times r) = f\,(r \cdot r) - r\,(r \cdot f) = f .
$$

$u$ is the component of $a$ perpendicular to $f$, normalized: by the same identity $f \times (a \times f) = a - (a \cdot f)\, f$, so "up" on the screen is as close to $a$ as the viewing direction allows. If $a \parallel f$ the cross product vanishes, `normalize_vec` returns zero, and the frame degenerates; this is a precondition of `look_at`, not a checked error.

### The view transform

Let $R = [\,r \mid u \mid f\,]$ be the matrix with the frame as columns. It is orthogonal, so $R^{-1} = R^\mathsf{T}$. The camera-to-world map sends camera coordinates $c$ to $e + R c$; inverting it gives the world-to-camera map

$$
c = R^\mathsf{T} (p - e) = R^\mathsf{T} p - R^\mathsf{T} e,
\qquad
V = \begin{pmatrix} R^\mathsf{T} & -R^\mathsf{T} e \\ 0^\mathsf{T} & 1 \end{pmatrix}
= \begin{pmatrix}
r^\mathsf{T} & -r \cdot e \\
u^\mathsf{T} & -u \cdot e \\
f^\mathsf{T} & -f \cdot e \\
0^\mathsf{T} & 1
\end{pmatrix},
$$

which is exactly the matrix that `Camera3::view_transform` builds. Two checks: $V e = 0$ (the eye goes to the origin) and $V t = (0, 0, \lVert t - e \rVert)$ (the target lies straight ahead on the positive $z$ axis). Because $V$ is a rigid motion ($\det R^\mathsf{T} = +1$), it preserves lengths, angles and dot products. In particular the Lambert term $\hat n \cdot \ell$ has the same value in world and camera space, which is why the frontend may compute lighting after the view transform.

### Handedness

The screen shows $r$ to the right and $u$ upwards, and $f = r \times u$ points into the screen. In a right-handed reading of the axes, right $\times$ up points *towards* the viewer; here it points away. The convention is therefore the left-handed one of Direct3D: with `Camera3::default`, world $+x$ appears on the right, $+y$ up, and $+z$ goes away from the viewer. Front faces of the generated meshes appear clockwise on the screen, as in Direct3D. Everything in `geometry3d` is consistent with this reading; a scene modelled for a right-handed system appears mirrored left to right.

### Perspective projection

A pinhole camera at the origin, looking along $+z$, forms the image of the point $(x, y, z)$ on a plane at distance $\varphi$ in front of the pinhole. By similar triangles the image is at

$$
\left( \varphi \frac{x}{z},\ \varphi \frac{y}{z} \right).
$$

`PerspectiveProjection::project_point` scales this by pixels per unit, moves the origin to the centre of a $W \times H$ viewport, and flips $y$ so that it grows downwards as screen rows do. Absorbing $\varphi$ and the pixel density into one scale $s$:

$$
x_s = \frac{W}{2} + s\,\frac{x}{z},\qquad
y_s = \frac{H}{2} - s\,\frac{y}{z} .
$$

In homogeneous coordinates this is the intrinsic matrix $K$ followed by the perspective divide:

$$
K = \begin{pmatrix} s & 0 & W/2 \\ 0 & -s & H/2 \\ 0 & 0 & 1 \end{pmatrix},\qquad
K \begin{pmatrix} x \\ y \\ z \end{pmatrix} = \begin{pmatrix} s x + \tfrac{W}{2} z \\ -s y + \tfrac{H}{2} z \\ z \end{pmatrix}
\ \xrightarrow{\ \div z\ }\ 
\begin{pmatrix} x_s \\ y_s \\ 1 \end{pmatrix}.
$$

The usual graphics pipeline splits $K$ into a projection to normalized device coordinates $[-1, 1]^2$ and a separate viewport transform. `view` fuses the two, because no stage in between needs normalized coordinates. It also keeps the camera-space $z$ as the depth instead of a normalized depth. A normalized depth of the form $a + b/z$ is a monotonic function of $z$, so both give the same depth-test results. Keeping $z$ makes depth values readable in world units and lets the rasterizer interpolate $1/z$ directly (below).

### Orthographic projection

Dropping the division gives the parallel projection $x_s = W/2 + s x$, $y_s = H/2 - s y$, with $s$ now in pixels per world unit. Sizes no longer shrink with distance. `OrthographicProjection` exists for points and for diagrams; the frontend does not rasterize with it.

### Perspective-correct depth

A rasterizer knows the projected vertices $p_0, p_1, p_2$ and, for each pixel, the screen-space barycentric coordinates $\lambda_i$ with $\sum \lambda_i = 1$ and $p = \sum \lambda_i p_i$. It needs the depth $z$ of the 3D point that projects to that pixel. Interpolating $z$ linearly with $\lambda$ is wrong, because projection does not preserve ratios along a line. The correct rule is:

> On a projected triangle, $1/z$ is an affine function of the screen position, so $\dfrac{1}{z} = \displaystyle\sum_i \frac{\lambda_i}{z_i}$.

Derivation. Let $P = \sum \mu_i P_i$ be the 3D point, with 3D barycentric coordinates $\mu_i$ ($\sum \mu_i = 1$), so its depth is $z = \sum \mu_i z_i$. Measure screen positions from the centre, $\tilde x_s = x_s - W/2$. Then

$$
\begin{aligned}
\tilde x_s(P) = s\,\frac{x}{z} = \frac{s}{z} \sum_i \mu_i x_i
= \sum_i \frac{\mu_i z_i}{z} \cdot s\,\frac{x_i}{z_i}
= \sum_i \frac{\mu_i z_i}{z}\, \tilde x_s(P_i),
\end{aligned}
$$

and the same computation holds for $y$. The weights $\mu_i z_i / z$ sum to $\big(\sum \mu_i z_i\big)/z = 1$, so they are the screen-space barycentric coordinates of $p$, which are unique for a non-degenerate triangle:

$$
\lambda_i = \frac{\mu_i z_i}{z} .
$$

Dividing by $z_i$ and summing,

$$
\sum_i \frac{\lambda_i}{z_i} = \sum_i \frac{\mu_i}{z} = \frac{1}{z}. \qquad\blacksquare
$$

`interpolate_perspective_depth` evaluates exactly this. The error of linear interpolation can be large: on an edge from depth $1$ to depth $3$, the screen midpoint has true depth $(\tfrac12 \cdot 1 + \tfrac12 \cdot \tfrac13)^{-1} = 1.5$, while the linear average says $2$. Between two intersecting or nearly touching surfaces, that difference decides which one is visible, and a test in the repository checks that the depth buffer uses the correct value.

Three remarks follow from the derivation:

- Any affine change of screen coordinates leaves the $\lambda_i$ unchanged, since barycentric coordinates are affine invariants. The terminal $y$ scaling of the TUI backend is such a map, so the rule stays exact after it.
- For an orthographic projection $z$ itself is affine in the screen position, and the $1/z$ rule would not be exact; this is why the frontend uses linear depth in its (orthographic) shadow map and never feeds orthographic triangles to these rasterizers.
- The rule needs $z_i > 0$. When a vertex is at or behind the eye, the code falls back to linear interpolation, which is at least finite; the image is wrong in that case anyway because nothing is clipped.

### The physical camera

A real camera with focal length $f$ (mm) and a sensor of height $h$ (mm) forms the image of $(x, y, z)$ at height $f\,y/z$ mm on the sensor, by the pinhole formula with $\varphi = f$. If the sensor height is shown on $H$ rows of the viewport, there are $H/h$ pixels per millimetre, so

$$
y_s - \frac{H}{2} = -\frac{H}{h} \cdot f\,\frac{y}{z}
\quad\Longrightarrow\quad
s = \frac{H f}{h},
$$

which is `ScientificCamera::projection_scale`. The angle of view across a sensor dimension $d$ follows from the right triangle formed by the pinhole, the sensor centre and the sensor edge:

$$
\tan\frac{\theta_d}{2} = \frac{d/2}{f}
\quad\Longrightarrow\quad
\theta_d = 2 \arctan\frac{d}{2 f},
$$

the formula of `LensSpec::horizontal_fov`, `vertical_fov` and `diagonal_fov`. With this scale, a point on the edge of the vertical field ($y/z = \tan(\theta_h/2) = h/2f$) lands at $y_s = H/2 - s\,h/2f = 0$, the top row: the vertical angle of view spans the viewport height exactly. Horizontally the viewport spans $2\arctan\!\big(\tfrac{W}{H} \cdot \tfrac{h}{2f}\big)$, which equals the sensor's horizontal field only when $W/H = w/h$. A 640 × 480 canvas (4:3) with a full-frame sensor (3:2) therefore shows a slightly narrower horizontal field than the lens would.

Units cancel in $s$: $f$ and $h$ are both millimetres, and $x/z$ is a ratio of world lengths. Scaling the whole scene and the camera distance by the same factor leaves the image unchanged, so `WorldUnit` does not enter the projection. It is used by `focal_length_world_units` and `sensor_height_world_units`, which express the optics in scene units for callers that want them.

### Dolly zoom

An object of height $Y$ at distance $d$ appears $s\,Y/d = H f Y / (h d)$ pixels tall. Keeping it the same size while the camera moves requires $f/d$ to be constant, that is $f(d) = f_0\, d / d_0$. Objects at other distances $d + \Delta$ then change size by the factor $\frac{d}{d + \Delta} \cdot \frac{d_0 + \Delta}{d_0}$, which is the "vertigo" effect the `demo` packages animate with `ScientificCamera::with_lens`.

## Design decisions

### A look-at camera with a derived frame

The problem: callers should be able to aim a camera without computing an orthonormal frame. A look-at description $(e, t, a)$ is what people think in, and the Gram–Schmidt-like construction above turns it into a rigid transform. Storing the three vectors (and not the matrix) keeps `Camera3` easy to animate: move `eye`, keep `target`. The cost is that each `world_to_camera_*` call rebuilds the frame; the frontend calls it per vertex, which is acceptable at demo scale.

### Fusing projection and viewport, keeping camera depth

Normalized device coordinates exist so that a GPU can clip and map to any framebuffer. `geometry3d` has no clipper and every backend draws in viewport units, so a separate NDC stage would add a step and no capability. Keeping $z$ as the depth makes the depth buffer hold distances along the view axis, and turns the perspective-correct rule into the short formula above.

### Physical parameters for perspective

A field-of-view number hides two things that photographers control separately: the lens and the sensor. `ScientificCamera` takes both, which makes a dolly zoom a matter of changing one focal length, and makes the scale follow from first principles. The scale is tied to the viewport *height* so that a vertical field of view, the convention of most cameras and graphics APIs, is preserved when the viewport width changes.

### Lenient constructors

Sensor, lens and world-unit constructors replace non-positive values by `1.0` instead of returning an error. These values come from code, not from users, and a visible but wrong picture is easier to debug in a renderer than an error path in every frame. `Viewport::new` and `Camera3::look_at` do no validation at all.

## Correctness and invariants

- $(r, u, f)$ is orthonormal with $r \times u = f$ whenever `up` is not parallel to the viewing direction.
- `view_transform` is a rigid motion: it maps the eye to the origin and the target to $(0, 0, \lVert t - e \rVert)$, and preserves distances and dot products.
- For $z > 0$, `PerspectiveProjection::project_point` agrees with $K$ followed by the perspective divide; `depth` is the camera-space $z$, so depth comparisons are comparisons of distance along the view axis.
- `interpolate_perspective_depth` returns the exact depth of the 3D point under a pixel (up to rounding) when all three vertex depths exceed `DEPTH_EPSILON`, as derived above.
- `projection_scale` maps the vertical angle of view onto the viewport height: $s \tan(\theta_h/2) = H/2$.
- All functions are constant time; the batch projection functions are linear in the number of points.

## Alternatives rejected

- **A 4×4 projection matrix applied with `Transform3`.** It would work (`apply_point` divides by $w$), but would replace the depth by a normalized value and require a viewport step afterwards; the three explicit formulas are clearer.
- **Clipping against a near plane.** It is the correct way to handle geometry that crosses the eye plane, but it splits triangles into polygons and needs a clipper in every path. The demos keep all geometry in front of the camera instead.
- **A field-of-view parameter.** It is derivable from `LensSpec` and `SensorSpec`, but cannot express a sensor change or a dolly zoom as directly.

## Boundaries

`view` does not:

- clip geometry, define near or far planes, or handle points at or behind the eye;
- unproject screen points back into rays;
- model depth of field, lens distortion, exposure or a non-centred principal point;
- correct for non-square pixels or terminal cells (the TUI backend does that);
- rasterize, shade or own any output format.
