# core design

## Design goal

`core` is the part of `geometry3d` that every other package agrees on: what a mesh is, how a point moves under a transform, which side of a face is the outside, and how bright a face is under a light. It must be small enough to read in one sitting, exact about its conventions, and free of anything that belongs to a camera, a screen or an output device. It is also a demonstration that the dense types of `Luna-Flow/linear-algebra` are enough to carry a 3D pipeline.

## Constraints

- Vectors and matrices are the dense `Double` types of `Luna-Flow/linear-algebra`; the package adds no vector type of its own.
- Every other package depends on `core`, so it may not depend on cameras, screens or output devices.
- Meshes must be usable by three rasterizers and by back-face culling, so the face type has to carry an orientation.

## Mathematical background

### Homogeneous coordinates

An affine map $x \mapsto A x + t$ of $\mathbb{R}^3$ is not linear, so it has no 3×3 matrix. Embedding $\mathbb{R}^3$ in $\mathbb{R}^4$ fixes this. A point $p$ is written $(p, 1)$ and a direction $d$ is written $(d, 0)$, and the affine map becomes the block matrix

$$
M = \begin{pmatrix} A & t \\ 0^\mathsf{T} & 1 \end{pmatrix},\qquad
M \begin{pmatrix} p \\ 1 \end{pmatrix} = \begin{pmatrix} A p + t \\ 1 \end{pmatrix},\qquad
M \begin{pmatrix} d \\ 0 \end{pmatrix} = \begin{pmatrix} A d \\ 0 \end{pmatrix}.
$$

The last coordinate records what kind of object a vector is. A direction is the difference of two points, $(p, 1) - (q, 1) = (p - q, 0)$, and the computation above shows that it is moved by $A$ alone: translating both points does not change their difference. This is exactly the split between `Transform3::apply_point` (which appends $w = 1$) and `Transform3::apply_direction` (which appends $w = 0$).

A general 4×4 matrix also has a last row $(h^\mathsf{T}, k) \ne (0, 0, 0, 1)$. It then sends $(p, 1)$ to $(x', y', z', w')$ with $w' = h \cdot p + k$, and the point it represents is found by the *homogeneous division* $(x'/w', y'/w', z'/w')$. Because $(x', y', z', w')$ and $\lambda (x', y', z', w')$ give the same point for every $\lambda \ne 0$, these matrices act on projective space; they include the perspective projection that `view` uses. `apply_point` always divides, so it handles both cases, and skips the division when $|w'| \le \varepsilon$ = `DEPTH_EPSILON`, that is, for points sent to (or near) the plane at infinity.

### Composition

For two transforms $M_1$ (applied first) and $M_2$ (applied second) the composite acts on a column vector as $M_2 (M_1 v) = (M_2 M_1) v$ by associativity of the matrix product. `Transform3::compose` stores $M_2 M_1$:

$$
\texttt{t1.compose(t2)}.\mathrm{matrix} = M_2 M_1 .
$$

The method reads in application order while the matrix product reads right to left. Two consequences follow from the algebra. Composition is associative, so a chain can be grouped freely. It is not commutative: with $T$ a translation by $t$ and $R$ a rotation,

$$
T R \begin{pmatrix} p \\ 1 \end{pmatrix} = \begin{pmatrix} R p + t \\ 1 \end{pmatrix}
\quad\ne\quad
R T \begin{pmatrix} p \\ 1 \end{pmatrix} = \begin{pmatrix} R p + R t \\ 1 \end{pmatrix}
$$

unless $R t = t$. The usual model transform therefore scales, then rotates, then translates: `s.compose(r).compose(t)`, matrix $T R S$.

### Elementary rotations

A linear map is determined by the images of the basis vectors, which form the columns of its matrix. Rotating the $xy$-plane by $\theta$ about the $z$ axis sends

$$
e_x \mapsto (\cos\theta, \sin\theta, 0),\qquad e_y \mapsto (-\sin\theta, \cos\theta, 0),\qquad e_z \mapsto e_z ,
$$

which gives the matrix $R_z(\theta)$ of `rotation_z`. The rotations about $x$ and $y$ follow by cycling the axes $x \to y \to z \to x$: about $x$ the pair $(y, z)$ plays the role of $(x, y)$, and about $y$ the pair $(z, x)$ does. The second substitution is why the minus sign of $R_y$ sits below the diagonal:

$$
R_y(\theta):\quad e_z \mapsto (\sin\theta, 0, \cos\theta),\qquad e_x \mapsto (\cos\theta, 0, -\sin\theta).
$$

Each $R$ is orthogonal with determinant $+1$: its columns are orthonormal, and $\det R_z(\theta) = \cos^2\theta + \sin^2\theta = 1$. Hence $R^{-1} = R^\mathsf{T} = R(-\theta)$, and rotations preserve lengths, angles and the orientation of a frame (they map a right-handed triple to a right-handed one).

### Euler angles

`rotation_matrix(α, β, γ)` composes the elementary rotations as $R = R_z(\gamma) R_y(\beta) R_x(\alpha)$. Writing $c_\bullet = \cos$ and $s_\bullet = \sin$ of the corresponding angle and multiplying out,

$$
\begin{aligned}
R_y(\beta) R_x(\alpha) &= \begin{pmatrix} c_\beta & s_\beta s_\alpha & s_\beta c_\alpha \\ 0 & c_\alpha & -s_\alpha \\ -s_\beta & c_\beta s_\alpha & c_\beta c_\alpha \end{pmatrix},\\[4pt]
R &= \begin{pmatrix}
c_\gamma c_\beta & c_\gamma s_\beta s_\alpha - s_\gamma c_\alpha & c_\gamma s_\beta c_\alpha + s_\gamma s_\alpha \\
s_\gamma c_\beta & s_\gamma s_\beta s_\alpha + c_\gamma c_\alpha & s_\gamma s_\beta c_\alpha - c_\gamma s_\alpha \\
-s_\beta & c_\beta s_\alpha & c_\beta c_\alpha
\end{pmatrix}.
\end{aligned}
$$

Applied to a column vector, the rotation about $x$ acts first, then $y$, then $z$, each about the fixed world axes (extrinsic $x$-$y$-$z$, equivalently intrinsic $z$-$y'$-$x''$). A product of rotations is a rotation, so by Euler's rotation theorem $R$ is a single rotation by some angle $\theta$ about some axis, with $\operatorname{tr} R = 1 + 2\cos\theta$.[^euler]

[^euler]: The trace is invariant under change of basis, and in a basis whose third vector is the axis the matrix is $R_z(\theta)$, whose trace is $1 + 2\cos\theta$. `geometry3d` does not extract the axis and angle; the identity is useful for checking a composed rotation in a test.

Euler angles have a singularity. At $\beta = \pi/2$ the matrix becomes

$$
R = \begin{pmatrix} 0 & \sin(\alpha - \gamma) & \cos(\alpha - \gamma) \\ 0 & \cos(\alpha - \gamma) & -\sin(\alpha - \gamma) \\ -1 & 0 & 0 \end{pmatrix},
$$

which depends on $\alpha - \gamma$ only: changing $\alpha$ and $\gamma$ by the same amount gives the same rotation. One degree of freedom is lost (gimbal lock), and near $\beta = \pm\pi/2$ small changes of orientation need large changes of the angles. The demos animate the three angles with independent constant rates, where this does not matter.

### Faces, normals and orientation

A face $(a, b, c, d)$ lies in a plane when its four vertices do. Its normal is computed from the first three:

$$
n = (v_b - v_a) \times (v_c - v_a),\qquad \hat n = n / \lVert n \rVert .
$$

The cross product is antisymmetric, so swapping two vertices reverses $n$; the vertex order *is* the orientation. The convention is that $\hat n$ points out of the solid; `cube_mesh`, `sphere_mesh` and `torus_mesh` follow it, and `cylinder_mesh`, `cone_mesh` and `triangular_pyramid_mesh` violate it (see below). For the cube face $(0, 3, 2, 1)$ at $z = -s$:

$$
\begin{aligned}
v_3 - v_0 &= (0, 2s, 0), \qquad v_2 - v_0 = (2s, 2s, 0),\\
(0, 2s, 0) \times (2s, 2s, 0) &= (2s \cdot 0 - 0 \cdot 2s,\ 0 \cdot 2s - 0 \cdot 0,\ 0 \cdot 2s - 2s \cdot 2s) = (0, 0, -4s^2),
\end{aligned}
$$

which points to $-z$, away from the cube. For the torus $P(u, v) = ((R + r\cos v)\cos u,\ r \sin v,\ (R + r\cos v)\sin u)$ the face at $(u, v)$ uses the vertices $P(u, v)$, $P(u, v + \Delta v)$, $P(u + \Delta u, v + \Delta v)$. To first order the two edges are $P_v \Delta v$ and $P_v \Delta v + P_u \Delta u$, so

$$
n \approx (P_v \times P_u)\, \Delta u\, \Delta v ,
$$

and at $u = v = 0$, $P_v = (0, r, 0)$ and $P_u = (0, 0, R + r)$ give $P_v \times P_u = (r (R + r), 0, 0)$: the normal points away from the axis, out of the tube. A test in the repository checks this so that back-face culling cannot regress to showing the inner wall.

The same computation shows that the other three generators are wound inwards. The first side face of `cylinder_mesh` is $(b_0, b_1, t_1, t_0)$ with $b_k = (r\cos\theta_k, -h, r\sin\theta_k)$ and $t_k$ the same point at height $+h$. At $\theta_0 = 0$, to first order in $\Delta = \theta_1$,

$$
b_1 - b_0 \approx (0, 0, r\Delta),\qquad t_1 - b_0 \approx (0, 2h, r\Delta),\qquad
(0, 0, r\Delta) \times (0, 2h, r\Delta) = (-2hr\Delta, 0, 0),
$$

which points towards the axis. The bottom cap $(\text{centre}, b_1, b_0)$ gives $(r\cos\Delta, 0, r\sin\Delta) \times (r, 0, 0) = (0, r^2\sin\Delta, 0)$, upwards into the solid, and the cone sides and the pyramid faces are wound the same way. Back-face culling therefore keeps the far, inner side of these three solids. This is a defect of the generators; the [core API](../api/core.md#cube_mesh-sphere_mesh-cylinder_mesh-cone_mesh-triangular_pyramid_mesh-torus_mesh) shows a workaround.

Every quad the generators emit is planar, so its normal is well defined. For the sphere and the torus, the face between the parameters $u, u'$ is symmetric under the reflection in the plane through the $y$ axis at angle $(u + u')/2$, which swaps $P(u, v) \leftrightarrow P(u', v)$ and $P(u, v') \leftrightarrow P(u', v')$. The segments $P(u, v)P(u', v)$ and $P(u, v')P(u', v')$ are both perpendicular to that mirror plane, hence parallel, and two parallel segments span a plane. Cube, cylinder sides and degenerate quads are planar by construction.

### Back-face visibility

A point $e$ sees the front side of a planar face exactly when it lies in the open half-space the normal points into:

$$
\hat n \cdot (e - q) > 0 \quad\text{for a point } q \text{ of the plane.}
$$

The sign does not depend on the choice of $q$: for two points $q, q'$ of the plane, $\hat n \cdot (q - q') = 0$, so $\hat n \cdot (e - q) = \hat n \cdot (e - q')$. `face_is_visible` takes $q$ = `face_center`. For a closed solid, a face whose back is turned to the eye is hidden by the front faces of the same solid, so culling it never removes visible surface; it roughly halves the work of the rasterizers. It does not resolve occlusion between different front faces; that is the job of the depth buffer.

### Lambert shading

A small surface patch of area $A$ with unit normal $\hat n$, lit by parallel rays travelling against the unit direction $\ell$, intercepts the flux crossing an area $A \cos\theta$ perpendicular to the rays, where $\cos\theta = \hat n \cdot \ell$. A perfectly diffuse (Lambertian) surface reflects light equally in all directions, so its apparent brightness is proportional to $\cos\theta$, and to zero when the light is behind the surface:

$$
I = \max(0,\ \hat n \cdot \ell) \in [0, 1] .
$$

`face_intensity` returns exactly this, which is why `light` must be a unit vector pointing towards the light. One value per face gives flat (faceted) shading.

## Design decisions

### Quads as the canonical topology

The problem: meshes need one face type that every generator, the culling test and the rasterizers understand. The options were triangles only, quads only, or general polygons. Quads were chosen because the parametric surfaces of the generators (sphere, cylinder, torus) are grids in $(u, v)$, whose cells are quads; one quad has one normal and one shading value, which halves the face count of flat shading. Triangles are embedded as degenerate quads with $d = a$, so a pyramid, a cone side or a sphere cap fits the same type. `triangulate_quad` turns a quad into two triangles only where a rasterizer needs them, and the zero-area second triangle of a degenerate quad is dropped by the area test.

### Points and directions as separate operations

`Transform3` stores one 4×4 matrix and exposes `apply_point` and `apply_direction` instead of asking callers to build $w$ themselves. This keeps the homogeneous convention inside the package and makes the rule "directions ignore translations" impossible to get wrong at a call site.

### Normals recomputed, not transformed

Normals do not transform like directions under a non-uniform scale: the correct matrix for normals is $(A^{-1})^\mathsf{T}$, because the tangent $t$ of a surface satisfies $n \cdot t = 0$, and after the map $t' = A t$ the vector $n' = A^{-\mathsf{T}} n$ keeps $n' \cdot t' = n^\mathsf{T} A^{-1} A t = 0$. Instead of storing normals and transforming them with this matrix, `core` recomputes $\hat n$ from transformed vertices every time (`face_normal` after `apply_mesh`). The two agree because of the cofactor identity

$$
(A u) \times (A v) = \det(A)\, A^{-\mathsf{T}} (u \times v)
\qquad\text{for invertible } A ,
$$

which follows from $w \cdot \big((Au) \times (Av)\big) = \det[\,w \mid Au \mid Av\,] = \det A \cdot \det[\,A^{-1} w \mid u \mid v\,] = \det A \cdot (A^{-1} w) \cdot (u \times v)$ for every $w$. Applied to the two edge vectors of a face, the recomputed normal is $\det A$ times the transformed one. The cost is one cross product per face; the benefit is that normals are always correct for any affine map with $\det A > 0$, including non-uniform scales. A map with $\det A < 0$ (a reflection) multiplies every normal by a negative number, so it reverses the winding and turns every face inside out.

### Euler angles instead of axis-angle or quaternions

The demos only need to spin objects with independent rates about three axes, which is exactly what Euler angles express, and the matrices are three lines each. Axis-angle construction (Rodrigues' formula) and quaternion composition are not implemented; `Luna-Flow/quaternion` is the place for them. Any rotation matrix produced elsewhere can be passed in with `Transform3::from_matrix`.

### A shared tolerance

`DEPTH_EPSILON` = $10^{-9}$ is used for every "is this zero?" decision in the pipeline: normalization, homogeneous division, triangle area, and the strict depth tests `depth + ε < stored`. One constant makes the behaviour at the degenerate boundary consistent across packages. It is an absolute tolerance, so it assumes scene coordinates of order $1$ to $10^3$; the demos use units of about one.

## Correctness and invariants

- `apply_point` on an affine transform is exact up to floating-point rounding: $w' = 1$, so no division error is introduced.
- `compose` satisfies $\texttt{t1.compose(t2).apply\_point}(p) = \texttt{t2.apply\_point}(\texttt{t1.apply\_point}(p))$ for affine transforms, and up to the homogeneous scale for projective ones. A test checks the order with a translation followed by a scale.
- Rotation matrices are orthogonal with determinant $1$; products of them are again rotations.
- Generated meshes are closed, centred on the origin, with planar faces. `face_is_visible` and `face_intensity` rely on outward normals, which `cube_mesh`, `sphere_mesh` and `torus_mesh` have and `cylinder_mesh`, `cone_mesh` and `triangular_pyramid_mesh` do not.
- `normalize_vec` and `face_normal` never divide by a number smaller than `DEPTH_EPSILON`; degenerate inputs yield the zero vector, which makes the face invisible and unlit.
- Every operation allocates a new vector or mesh; no function mutates its arguments. `apply_mesh` shares the face array of its input.

Each function is constant time except the generators and `apply_mesh`, which are linear in the number of vertices and faces.

## Alternatives rejected

- **A dedicated small-vector type** (`Vec3` struct with `x`, `y`, `z` fields) would be faster and type-safe about dimensions, but would duplicate `linear-algebra`. The point of the repository is to build on the Luna-Flow base, so vectors are `@la.Vector[Double]` and dimensions are a convention.
- **Generic scalars** (`Mesh[T]` over any `Field`) were rejected: trigonometry, square roots and the tolerance all assume `Double`, and no backend could use another type.
- **Storing normals in the mesh** was rejected for the reason given above: recomputing them is cheap and always correct after a transform.
- **Triangle meshes as the primary type** would make every flat-shaded grid face two faces with two identical normals.

## Boundaries

`core` does not:

- know about cameras, projections, viewports, terminals, colours or the DOM;
- let code outside the package build arbitrary meshes: the fields of `Mesh` and `QuadFace` are read-only outside it, so the generators are the only source of meshes;
- load or save meshes, or provide scene graphs, materials, textures, physics or spatial indices;
- compute smooth (per-vertex) normals, clip geometry, or test intersections;
- provide inverse transforms, axis-angle or quaternion rotations.
