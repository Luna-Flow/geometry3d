moon test
moon test --target wasm-gc
moon test --target js
moon test --target native
moon test --target wasm
moon run src/demo --target native -- --sphere --once
moon run src/demo --target native -- --hitchcock --once
moon run src/demo --target native -- --camera-auto --once
moon run src/demo --target native -- --long-exposure --once
moon run src/demo --target native -- --hitchcock --flow-exposure --once
mkdir -p target
moon run src/demo --target native -- --record target/geometry3d-demo.tui3d --duration 1 --fps 2
moon run src/demo --target native -- --play target/geometry3d-demo.tui3d --once
moon run src/demo --target native -- --export-image target/geometry3d-demo.tuiimg
moon run src/demo --target native -- --show-image target/geometry3d-demo.tuiimg
