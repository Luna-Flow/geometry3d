# frontend design

## Design goal

The frontend is where a 3D scene stops being 3D. It owns every step that is the same for all outputs (model and view transforms, projection, visibility, lighting and shadows) and hands the backends a flat list of screen-space triangles with one brightness each. A backend can then be written in an afternoon: it only decides how a triangle of a given brightness looks on its device. The same boundary lets the TUI, Canvas and SVG backends show the same picture from the same `DrawList`.

## Mathematical background

### The pipeline

For each object with mesh vertices $p$ and model matrix $M$, and a camera with view matrix $V$ and projection $\pi$ (see the [view design](view.md)), `build_draw_list` computes

$$
p_w = M p,\qquad p_c = V p_w,\qquad (x_s, y_s, z) = \pi(p_c),
$$

and for each face $F$ with camera-space normal $\hat n_F$ and centre $c_F$:

$$
\text{emit } F \iff \hat n_F \cdot (0 - c_F) > 0,\qquad
I_F = \max(0, \hat n_F \cdot \ell_c)\,\big(\alpha + (1 - \alpha)\, v_F\big),
$$

with the camera at the origin of camera space, $\ell_c = \operatorname{normalize}(V \ell)$ the light direction in camera space (a direction, so $w = 0$), the ambient factor $\alpha = 0.35$, and the shadow visibility $v_F \in [0, 1]$ below. Since $V$ is a rigid motion, $\hat n_F \cdot \ell_c$ equals the world-space Lambert term; computing it in camera space avoids a second set of normals. Each emitted quad becomes the two triangles of `triangulate_quad`, both carrying $I_F$.

### Shadow mapping

A point is in shadow when some other surface lies between it and the light. For a directional light all rays are parallel to $\ell$, so the test reduces to comparing distances along $\ell$ inside a parallel (orthographic) projection.[^williams]

[^williams]: Lance Williams, "Casting curved shadows on curved surfaces", SIGGRAPH 1978, introduced the depth-map technique.

**Light camera.** Let $c$ be the centre of the scene's world-space bounding box and $\rho = \max(1, \max_p \lVert p - c \rVert)$. The frontend places a `Camera3` at $c + (2\rho + 1)\,\ell$ looking at $c$, with up $= +y$ (or $+z$ when $|\ell \cdot y| > 0.99$, to keep the frame non-degenerate). Every vertex is at least $\rho + 1$ units in front of it. In this camera's space, $x_\ell$ and $y_\ell$ are coordinates across the light rays, and $z_\ell$ is the distance along them away from the light.

**Grid.** Over the light-space bounding box of all vertices, padded on each side by $\max(0.05 \cdot \text{span}, 0.25)$, the map lays an $N \times N$ grid with $N = 128$:

$$
X = \frac{x_\ell - x_{\min}}{x_{\max} - x_{\min}}\,(N - 1),\qquad
Y = \frac{y_{\max} - y_\ell}{y_{\max} - y_{\min}}\,(N - 1).
$$

**Depth pass.** Every triangle of every object, front- or back-facing, is rasterized into the grid with the rule below, keeping in each texel the smallest $z_\ell$ (the surface nearest the light). Depth is interpolated linearly with the barycentric coordinates, which is exact here: on a plane $a x + b y + c z = d$ with $c \ne 0$, $z = (d - a x - b y)/c$ is affine in $(x, y)$, and the grid map is affine too.

**Lookup.** To test a world point $q$, the frontend moves it towards the light by twice the bias $b$, maps it into the grid and rounds to the nearest texel $(X^\ast, Y^\ast)$. Moving by $2b$ along $\ell$ lowers $z_\ell$ by exactly $2b$, since the light camera's forward axis is $-\ell$. The point counts as lit if it falls outside the grid, if the texel is empty, or if

$$
z_\ell(q) - 2b \le D(X^\ast, Y^\ast) + b
\iff
z_\ell(q) \le D(X^\ast, Y^\ast) + 3b ,
$$

so the effective tolerance is $3b$, with $b = \max(0.005 \cdot \text{depth span}, 10^{-4})$.

**Why a bias is needed.** A surface shadowing itself because of the grid's finite resolution is called shadow acne. Rounding to the nearest texel centre moves the lookup by at most half a texel, $\Delta/2$, along each axis, where $\Delta$ is the texel size in light-space units. If the surface through $q$ has depth gradient $(z_x, z_y)$ in light space, the stored depth of its own texel differs from $z_\ell(q)$ by at most

$$
|D - z_\ell(q)| \le \big(|z_x| + |z_y|\big)\,\frac{\Delta}{2} .
$$

A face whose normal makes an angle $\theta$ with $\ell$ has $\lVert (z_x, z_y) \rVert = \tan\theta$, so the error grows without bound at grazing incidence. The tolerance $3b$ removes acne whenever $\sqrt2\,\tan\theta\,\Delta/2 \le 3b$. Where it does not, $\theta$ is close to $90°$ and the Lambert factor $\cos\theta$ already makes the face dark, so residual acne is hard to see. The price of the bias is that a shadow starts slightly late at contact points ("peter-panning"), by about $3b$ = 1.5% of the scene's depth span.

**Face visibility.** The frontend tests the centre and the four vertices of each face and averages:

$$
v_F = \tfrac15 \sum_{q \in \{c_F, v_a, v_b, v_c, v_d\}} \mathbb{1}[q \text{ lit}] \in \{0, 0.2, 0.4, 0.6, 0.8, 1\}.
$$

A face crossing a shadow boundary gets an intermediate value, which softens the boundary at face resolution instead of drawing a jagged edge across a flat-shaded face. The ambient term then keeps a fully shadowed face at $\alpha = 35\%$ of its Lambert brightness, so shape stays readable in shadow. Faces turned away from the light are not looked up; their intensity is $0$.

### Rasterization by edge functions

`LumaBuffer::draw_triangle` (and the TUI and shadow-map rasterizers, which use the same rule) decide coverage with edge functions. For points $a$, $b$, $p$ in the screen plane let

$$
E(a, b; p) = (p_x - a_x)(b_y - a_y) - (p_y - a_y)(b_x - a_x),
$$

an affine function of $p$ that vanishes on the line $ab$ and changes sign across it; $|E(a, b; p)|$ is twice the area of the triangle $abp$. For a triangle $p_0 p_1 p_2$ put

$$
A = E(p_0, p_1; p_2),\qquad
w_0 = E(p_1, p_2; p),\quad w_1 = E(p_2, p_0; p),\quad w_2 = E(p_0, p_1; p).
$$

Each $w_i$ is affine in $p$ and vanishes at the two vertices other than $p_i$. At $p = p_i$ it equals $A$, because the signed area is invariant under cyclic permutation of the vertices. Hence $w_0 + w_1 + w_2 - A$ is an affine function that vanishes at three non-collinear points, so

$$
w_0 + w_1 + w_2 = A \quad\text{for every } p,
\qquad
\lambda_i = \frac{w_i}{A}
$$

are the barycentric coordinates of $p$ ($\lambda_i(p_j) = \delta_{ij}$, $\sum \lambda_i = 1$). The point lies in the closed triangle exactly when all $\lambda_i \ge 0$, that is when all $w_i$ have the sign of $A$ or are zero. The code tests both signs, so the screen winding of a triangle does not matter: culling has already happened in 3D. Pixels are sampled at their centres $(x + \tfrac12, y + \tfrac12)$, only inside the triangle's bounding box, and triangles with $|A| \le$ `DEPTH_EPSILON` are skipped. The depth at a covered pixel is the perspective-correct $\big(\sum \lambda_i / z_i\big)^{-1}$.

### The depth buffer

`set_if_closer` writes a pixel only when the new depth is smaller than the stored one by more than $\varepsilon$ = `DEPTH_EPSILON`. By induction over the triangles drawn, after drawing $T_1, \dots, T_k$ every pixel holds the intensity of the triangle with the smallest depth among those covering it, and among triangles within $\varepsilon$ of that depth, the one drawn first. The base case is the empty buffer at depth $10^{30}$. In the step, $T_{k+1}$ replaces the stored value exactly when it is strictly nearer by more than $\varepsilon$. The final image is therefore independent of the drawing order except for near-ties, which is why the draw list is not sorted.

Edges are inclusive, without a "top-left" tie rule: a pixel centre exactly on an edge shared by two triangles is covered by both. The depth test keeps one of them. Both triangles of a quad have the same intensity, so this is invisible inside a face.

### Exposure and optical flow

A camera with shutter time $T$ records $\int_0^T L(x, t)\,dt$ at each pixel. The frontend approximates the normalized exposure by a Riemann sum over $N$ rendered samples,

$$
\bar L(x) = \frac1T \int_0^T L(x, t)\,dt \approx \frac1N \sum_{k=0}^{N-1} L(x, t_k),
$$

implemented by `LumaBuffer::add_weighted_sample` with weight $1/N$. Moving edges smear into motion blur.

The optional flow alignment assumes brightness constancy, $L_{\text{prev}}(x + d) \approx L_{\text{cur}}(x)$, and estimates the integer displacement $d$ per pixel by exhaustive block matching:

$$
d(x) = \operatorname*{arg\,min}_{\lVert d \rVert_\infty \le R}\ \sum_{\lVert o \rVert_\infty \le P} \big( L_{\text{prev}}(x + o + d) - L_{\text{cur}}(x + o) \big)^2 .
$$

Warping each sample by its flow before accumulating (`align_with_flow`) re-registers moving content onto the current frame, which trades blur for sharper, ghost-reduced edges. The estimate is integer-valued. It suffers from the aperture problem: in a uniform patch every $d$ fits, and the scan order then returns $(-R, -R)$.

## Design decisions

### The draw list is the boundary

The problem: three backends with very different output models (a character grid, a pixel canvas, retained SVG nodes) must show the same scene. Options were to hand them meshes (each backend re-implements projection and lighting), pixels (the SVG backend loses its vector output), or projected, shaded triangles. The last was chosen. A `DrawTriangle` contains exactly what every backend needs: screen coordinates, camera depth for occlusion, and a brightness in $[0, 1]$ that each backend maps to its own palette. Projection, culling, lighting and shadows are computed once, in one place, and tested once.

### Flat shading per quad

One intensity per face matches the faceted, low-polygon look of the demos and the coarse resolution of a terminal, and makes the draw list small. Smooth shading would need per-vertex normals, which `core` does not have, and an interpolated intensity per pixel, which the SVG backend cannot express.

### Shadows in the frontend

Shadows need the world-space geometry of the whole scene, which backends never see, so they belong in the frontend. A shadow map was chosen over ray casting: it costs one rasterization of the scene from the light and one lookup per sample point, reuses the existing rasterizer, and needs no acceleration structure. The resolution is fixed at 128 × 128 because visibility is only sampled five times per face; finer maps would not change flat-shaded output. The bounds are fitted to the scene every frame, so the full resolution is always used.

### A shared scalar buffer

`LumaBuffer` sits in the frontend, not in a backend, because three consumers need a scalar image with depth: the Canvas backend, the exposure accumulation and the optical flow. The TUI backend keeps its own character buffer for direct rendering, and uses `LumaBuffer` (through `draw_list_to_tui_luma`) for exposure effects.

### Time as data

`Timeline`, `ScalarTrack`, `ExposureSettings` and the flow functions are pure data and functions of buffers; they never call a clock. The demos decide when to render and which times to sample, which keeps the frontend deterministic and testable.

## Correctness and invariants

- Emitted triangles face the camera ($\hat n \cdot (0 - c) > 0$ in camera space) and have intensity in $[0, 1]$, up to rounding (a fully lit face may come out as $1 + 2^{-52}$), when the light direction is a unit vector; backends clamp it.
- The draw list is in scene order, object by object and face by face; two triangles per visible quad.
- `LumaBuffer` holds, per pixel, the nearest covering triangle's value (first drawn among $\varepsilon$-ties), as shown above.
- The shadow lookup never darkens a point that lies outside the map or under an empty texel; visibility is a multiple of $0.2$.
- `ExposureSettings` always has $0 < \text{shutter} \le \text{frame\_dt}$ and at least one sample; `auto` yields exactly one sample (the shutter is clamped before the count is taken).
- `Timeline::frame_count` is at least 1; sample times are $k/\mathit{fps}$; progress is clamped to $[0, 1]$.

Costs per frame: $O(V + F)$ for transforms, culling and shading; rasterization proportional to the covered bounding-box area of each triangle (for the shadow map and for `LumaBuffer`); five shadow lookups per lit visible face; $O(W H (2R+1)^2 (2P+1)^2)$ for optical flow.

## Alternatives rejected

- **Sorting the draw list by depth.** Correct occlusion comes from the depth buffer in the TUI and Canvas backends; the SVG backend sorts on its own because it has no depth buffer. Sorting in the frontend would impose one strategy on all.
- **Gouraud or Phong shading.** See "Flat shading per quad"; it would also make the TUI output noisier, not better.
- **Percentage-closer filtering over neighbouring texels.** Five samples per face already give the intermediate values that flat shading can show.
- **Clamping `ExposureSettings::auto` differently.** Allowing a shutter longer than a frame would let `auto` return several samples, but would make one frame integrate light from the next frame's interval.

## Boundaries

The frontend does not:

- clip geometry against the view volume or a near plane: all vertices must be in front of the camera;
- support point or spot lights, coloured light, several lights, materials or textures;
- produce characters, colours, pixels on a device, or files;
- sort, batch or cache draw lists between frames;
- estimate sub-pixel or dense variational optical flow.
