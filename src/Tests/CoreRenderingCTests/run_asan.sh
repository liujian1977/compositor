#!/bin/sh
# Build and run the CoreRendering C regressions under ASan, UBSan, and LSan.
# Usage: src/Tests/CoreRenderingCTests/run_asan.sh
# Exits non-zero on a sanitizer error or a failed pixel assertion.

set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/../../.." && pwd)
CORE="$ROOT/src/CompositorCore/CoreRendering"
TESTS="$ROOT/src/Tests/CoreRenderingCTests"
OUT=${TMPDIR:-/tmp}/compositor-c-tests
mkdir -p "$OUT"

# cc is clang on some images and may lack the ASan runtime. Prefer gcc when
# the caller did not choose a compiler.
if [ -z "${CC:-}" ]; then
    if command -v gcc >/dev/null 2>&1; then
        CC=gcc
    else
        CC=cc
    fi
fi
CFLAGS="-std=c11 -O1 -g -Wall -Wextra -Werror -fno-omit-frame-pointer -fno-sanitize-recover=all -fsanitize=address,undefined"
ASAN_OPTIONS=detect_leaks=1:halt_on_error=1:abort_on_error=1
UBSAN_OPTIONS=halt_on_error=1:abort_on_error=1:print_stacktrace=1
export ASAN_OPTIONS UBSAN_OPTIONS

echo "cc=$CC"
"$CC" --version

"$CC" $CFLAGS -DCOMPOSITOR_C_TESTS -I"$CORE" \
    "$TESTS/test_composite_poisson.c" "$CORE/CompositeOp.c" \
    -lm -o "$OUT/test_composite_poisson"
"$CC" $CFLAGS -DCOMPOSITOR_C_TESTS -I"$CORE" \
    "$TESTS/test_patch_inpaint.c" "$CORE/PatchInpaintOp.c" \
    -lm -o "$OUT/test_patch_inpaint"

"$OUT/test_composite_poisson"
"$OUT/test_patch_inpaint"
echo "ALL C SANITIZER TESTS PASSED"
