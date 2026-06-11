# Demo Tutorial

## Rotating Cube

```sh
moon run . --target native
```

The default demo renders a rotating cube with dotted background, Z-buffering,
backface culling, flat lighting, and terminal y-scale correction.

## Static Sphere

```sh
moon run . --target native -- --sphere
```

The sphere demo uses a higher-subdivision UV sphere and remains static so the
faceted lighting is easy to inspect.

## Smoke Tests

```sh
moon run . --target native -- --once
moon run . --target native -- --sphere --once
```

Use `--once` when validating the renderer in scripts or CI-like local checks.
