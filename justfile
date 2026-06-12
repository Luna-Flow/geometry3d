set shell := ["zsh", "-cu"]

default:
  @just --list

run *args:
  rtk moon run src/demo --target native -- -- {{args}}

hitchcock:
  lines="$(stty size 2>/dev/null | awk '{print $1}')"; cols="$(stty size 2>/dev/null | awk '{print $2}')"; if [[ -z "$lines" || "$lines" == "0" ]]; then lines="$(tput lines 2>/dev/null || printf '32')"; fi; if [[ -z "$cols" || "$cols" == "0" ]]; then cols="$(tput cols 2>/dev/null || printf '80')"; fi; LINES="$lines" COLUMNS="$cols" rtk moon run src/demo --target native -- --hitchcock

cube:
  lines="$(stty size 2>/dev/null | awk '{print $1}')"; cols="$(stty size 2>/dev/null | awk '{print $2}')"; if [[ -z "$lines" || "$lines" == "0" ]]; then lines="$(tput lines 2>/dev/null || printf '32')"; fi; if [[ -z "$cols" || "$cols" == "0" ]]; then cols="$(tput cols 2>/dev/null || printf '80')"; fi; LINES="$lines" COLUMNS="$cols" rtk moon run src/demo --target native --

dolly:
  lines="$(stty size 2>/dev/null | awk '{print $1}')"; cols="$(stty size 2>/dev/null | awk '{print $2}')"; if [[ -z "$lines" || "$lines" == "0" ]]; then lines="$(tput lines 2>/dev/null || printf '32')"; fi; if [[ -z "$cols" || "$cols" == "0" ]]; then cols="$(tput cols 2>/dev/null || printf '80')"; fi; LINES="$lines" COLUMNS="$cols" rtk moon run src/demo --target native -- --dolly

torus:
  lines="$(stty size 2>/dev/null | awk '{print $1}')"; cols="$(stty size 2>/dev/null | awk '{print $2}')"; if [[ -z "$lines" || "$lines" == "0" ]]; then lines="$(tput lines 2>/dev/null || printf '32')"; fi; if [[ -z "$cols" || "$cols" == "0" ]]; then cols="$(tput cols 2>/dev/null || printf '80')"; fi; LINES="$lines" COLUMNS="$cols" rtk moon run src/demo --target native -- --torus

tests:
  rtk moon test

tests-native:
  rtk moon test --target native

tests-js:
  rtk moon test --target js

tests-wasm:
  rtk moon test --target wasm

tests-wasm-gc:
  rtk moon test --target wasm-gc

canvas-build:
  rtk moon build src/demo_canvas --target js
  mkdir -p target/canvas-demo
  cp src/demo_canvas/index.html target/canvas-demo/index.html
  cp _build/js/debug/build/demo_canvas/demo_canvas.js target/canvas-demo/demo.js
  @printf 'Canvas demo built at target/canvas-demo/index.html\n'

canvas-serve: canvas-build
  python3 -m http.server 8080 -d target/canvas-demo

record:
  mkdir -p target
  rtk moon run src/demo --target native -- --record target/geometry3d-demo.tui3d --duration 1 --fps 2

export-image:
  mkdir -p target
  rtk moon run src/demo --target native -- --export-image target/geometry3d-demo.tuiimg

show-image:
  rtk moon run src/demo --target native -- --show-image target/geometry3d-demo.tuiimg
