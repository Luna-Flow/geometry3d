# Demo Tutorial

## Rotating Cube

```sh
moon run src/demo --target native
```

The default demo renders a rotating cube with dotted background, Z-buffering,
backface culling, flat lighting, and terminal y-scale correction.

## Static Sphere

```sh
moon run src/demo --target native -- --sphere
```

The sphere demo uses a higher-subdivision UV sphere and remains static so the
faceted lighting is easy to inspect.

## Hitchcock Zoom Scene

```sh
moon run src/demo --target native -- --hitchcock
```

This scene keeps a central cube visually stable while the camera distance and
projection scale change together. A cylinder, cone, triangular pyramid, and
rotated variants sit behind the cube, making the dolly zoom effect visible.

## Smoke Tests

```sh
moon run src/demo --target native -- --once
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --hitchcock --once
```

Use `--once` when validating the renderer in scripts or CI-like local checks.
