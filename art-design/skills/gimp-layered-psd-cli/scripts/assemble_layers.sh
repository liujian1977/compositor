#!/bin/bash
# Headless layered PSD + flattened PNG assembly via GIMP 2.10 script-fu (TinyScheme).
# Usage:
#   assemble_layers.sh <canvas_w> <canvas_h> <out.psd> <out.png> <layer>...
# Each <layer> is  path  or  path,x,y  or  path,x,y,scale  (comma-separated).
# Argument order = bottom-to-top layer stack (first arg = bottom).
#
# Verified on GIMP 2.10.38 macOS:
# - script-fu batch is stable; python-fu-eval hangs on PNG loads.
# - file-psd-save: 7 args; file-png-save: 10 args.
# - Do NOT call gimp-image-delete on the loaded source images inside let* —
#   it detaches canvas layers ("no visible layers" on flatten). Leaked source
#   images die with the process anyway.
# - Fallback `-b "(gimp-quit 0)"` prevents REPL hang on script errors.
set -euo pipefail

GIMP="${GIMP_BIN:-/Applications/GIMP.app/Contents/MacOS/gimp-console}"
CFG="${TMPDIR:-/tmp}/gimp-assemble-config"
DATA="${TMPDIR:-/tmp}/gimp-assemble-data"
mkdir -p "$CFG" "$DATA/gradients" "$DATA/brushes" "$DATA/patterns"

if [ $# -lt 5 ]; then
  echo "usage: $0 <w> <h> <out.psd> <out.png> <path[,x,y,scale]>..." >&2
  exit 1
fi

W=$1; H=$2; PSD=$3; PNG=$4; shift 4
mkdir -p "$(dirname "$PSD")" "$(dirname "$PNG")"

BIND=""; BODY=""; n=0
for spec in "$@"; do
  IFS=',' read -r path x y s <<< "$spec"
  if [ -z "${x:-}" ]; then x=0; fi
  if [ -z "${y:-}" ]; then y=0; fi
  if [ -z "${s:-}" ]; then s=1.0; fi
  if [ ! -f "$path" ]; then echo "missing layer file: $path" >&2; exit 1; fi
  n=$((n+1))
  BIND="$BIND
      (src$n (car (gimp-file-load RUN-NONINTERACTIVE \"$path\" \"$path\")))
      (ly$n (car (gimp-layer-new-from-drawable (car (gimp-image-get-active-drawable src$n)) img)))"
  BODY="$BODY
  (gimp-image-insert-layer img ly$n 0 -1)
  (if (not (= $s 1.0))
    (gimp-layer-scale ly$n (round (* (car (gimp-drawable-width ly$n)) $s)) (round (* (car (gimp-drawable-height ly$n)) $s)) FALSE))
  (gimp-layer-set-offsets ly$n $x $y)"
done

SCRIPT="(let* ((img (car (gimp-image-new $W $H RGB)))$BIND)
  $BODY
  (file-psd-save RUN-NONINTERACTIVE img (car (gimp-image-get-active-drawable img)) \"$PSD\" \"$(basename "$PSD")\" 1 0)
  (gimp-image-flatten img)
  (file-png-save RUN-NONINTERACTIVE img (car (gimp-image-get-active-drawable img)) \"$PNG\" \"$(basename "$PNG")\" 0 9 1 1 1 0 0))"

GIMP_CONFIG="$CFG" GIMP_DATA="$DATA" "$GIMP" -i -b "$SCRIPT" -b "(gimp-quit 0)" </dev/null 2>&1 | grep -Ev '^GIMP (is|was)|GEGL|GeglBuffer|保存数据|可写数据|修正首选项|^$' || true
ls -la "$PSD" "$PNG"
