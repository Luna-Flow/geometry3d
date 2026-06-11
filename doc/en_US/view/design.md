# View Design

## Responsibilities

- Convert world-space points and directions into camera space.
- Project camera-space points into viewport coordinates.
- Keep terminal and backend concerns outside the view package.

## Conventions

Camera-space positive `z` is in front of the camera. `Camera3::look_at` builds a
view transform using `right`, `true_up`, and `forward` basis vectors.

## Limitations

The first version exposes compact projection helpers instead of full clipping,
near/far planes, or unprojection.
