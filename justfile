set shell := ["zsh", "-cu"]

default:
  @just --list

fmt:
  moon fmt

update-deps:
  moon update
  awk ' \
    $1 == "import" && $2 == "{" { in_import = 1; next } \
    in_import && $1 == "}" { in_import = 0; next } \
    in_import { \
      gsub(/[",]/, "", $1); \
      sub(/@.*/, "", $1); \
      if ($1 != "") print $1; \
    } \
  ' moon.mod | while IFS= read -r dep; do \
    moon add --upgrade --no-update "$dep"; \
  done
  moon build

build:
  moon build

check:
  moon check

check-all:
  moon check --target all

test:
  moon test

test-matrix:
  bash ./run_test.sh

test-coverage:
  moon clean
  moon coverage clean
  moon test --enable-coverage
  if moon coverage report -f summary > coverage_summary.txt 2>/dev/null; then \
    moon coverage report -f html 2>/dev/null; \
  else \
    printf '%s\n' "coverage report generation failed with the current MoonBit toolchain" > coverage_summary.txt; \
    printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2; \
  fi

info:
  moon info

tree:
  moon tree

ready:
  moon fmt
  moon check --target all
  moon info
  bash ./run_test.sh
  moon clean
  moon coverage clean
  moon test --enable-coverage
  if moon coverage report -f summary > coverage_summary.txt 2>/dev/null; then \
    moon coverage report -f html 2>/dev/null; \
  else \
    printf '%s\n' "coverage report generation failed with the current MoonBit toolchain" > coverage_summary.txt; \
    printf '%s\n' "warning: moon coverage report failed; tests still passed" >&2; \
  fi

publish-dry-run:
  moon package --frozen

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
  just test

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

gsap-build:
  rtk moon build src/demo_gsap --target js
  mkdir -p target/gsap-demo
  cp src/demo_gsap/index.html target/gsap-demo/index.html
  cp _build/js/debug/build/demo_gsap/demo_gsap.js target/gsap-demo/demo.js
  @printf 'GSAP SVG demo built at target/gsap-demo/index.html\n'

gsap-serve: gsap-build
  python3 -m http.server 8081 -d target/gsap-demo

record:
  mkdir -p target
  rtk moon run src/demo --target native -- --record target/geometry3d-demo.tui3d --duration 1 --fps 2

export-image:
  mkdir -p target
  rtk moon run src/demo --target native -- --export-image target/geometry3d-demo.tuiimg

show-image:
  rtk moon run src/demo --target native -- --show-image target/geometry3d-demo.tuiimg
