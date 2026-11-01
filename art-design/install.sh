#!/usr/bin/env bash
# install.sh — install the art-design skill framework and its tools.
#
# Implements art-design/spec.md. Idempotent: every component is checked first
# and skipped if already present. Safe to re-run.
#
# Usage:
#   ./install.sh            # full install (will prompt for secrets via setup.sh)
#   ./install.sh --no-setup # install everything except secrets (run setup.sh later)
#
# Components handled:
#   - 14 CodeBuddy skills      -> ~/.codebuddy/skills/
#   - assets (knowledge.db, yolov8n.pt, comfyui_generate.py)
#                              -> ~/.codebuddy/assets/art-design/
#   - Python venv ~/.venv-art  (Pillow/numpy/opencv/ultralytics/requests)
#   - compositor CLI           -> build from repo root, link ~/.codebuddy/bin/compositor
#   - GIMP 2.10                -> checked only (must be installed manually on macOS)
#   - local_config.json secrets -> via setup.sh (NOT committed)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ART_DIR="$SCRIPT_DIR"

SKILLS_DST="$HOME/.codebuddy/skills"
ASSETS_DST="$HOME/.codebuddy/assets/art-design"
VENV="$HOME/.venv-art"
COMPOSITOR_LINK="$HOME/.codebuddy/bin/compositor"
NO_SETUP=0
for a in "$@"; do [ "$a" = "--no-setup" ] && NO_SETUP=1; done

PYTHON="${PYTHON:-$(command -v python3 || true)}"
if [ -z "$PYTHON" ] && [ -x "$VENV/bin/python" ]; then PYTHON="$VENV/bin/python"; fi

step() { echo; echo "== $1 =="; }

# 1) Skills -----------------------------------------------------------------
step "CodeBuddy skills -> $SKILLS_DST"
mkdir -p "$SKILLS_DST"
for d in "$ART_DIR"/skills/*/; do
  name="$(basename "$d")"
  if [ -e "$SKILLS_DST/$name" ]; then
    echo "  exists: $name (skip)"
  else
    cp -R "$d" "$SKILLS_DST/$name"
    echo "  installed: $name"
  fi
done

# 2) Assets -----------------------------------------------------------------
step "assets -> $ASSETS_DST"
mkdir -p "$ASSETS_DST"; chmod 700 "$ASSETS_DST"
for f in knowledge.db yolov8n.pt comfyui_generate.py; do
  if [ -e "$ASSETS_DST/$f" ]; then
    echo "  exists: $f (skip)"
  else
    cp "$ART_DIR/assets/$f" "$ASSETS_DST/$f"
    echo "  installed: $f"
  fi
done

# 3) Python venv ------------------------------------------------------------
step "Python venv -> $VENV"
if [ -x "$VENV/bin/python" ] && "$VENV/bin/python" -c "import PIL, numpy, cv2, ultralytics, requests" 2>/dev/null; then
  echo "  present & deps ok (skip)"
else
  if [ -z "$(command -v python3 || true)" ]; then
    echo "  error: python3 not found. Install Python 3.11+ first." >&2; exit 1
  fi
  echo "  creating venv + installing deps"
  rm -rf "$VENV"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -r "$ART_DIR/requirements.txt"
fi

# 4) compositor CLI ---------------------------------------------------------
step "compositor CLI"
if [ -x "${COMPOSITOR_BIN:-$COMPOSITOR_LINK}" ]; then
  echo "  binary present at ${COMPOSITOR_BIN:-$COMPOSITOR_LINK} (skip build)"
else
  if [ -z "$(command -v swift || true)" ]; then
    echo "  error: 'swift' not found. Install Xcode Command Line Tools (xcode-select --install)." >&2
    echo "  Then re-run this script." >&2; exit 1
  fi
  echo "  building from $REPO_ROOT (swift build)"
  ( cd "$REPO_ROOT" && swift build )
  mkdir -p "$HOME/.codebuddy/bin"
  BIN="$REPO_ROOT/.build/debug/compositor"
  ln -sf "$BIN" "$COMPOSITOR_LINK"
  echo "  linked -> $COMPOSITOR_LINK"
fi

# 5) GIMP (macOS) -----------------------------------------------------------
step "GIMP 2.10 (manual install)"
if [ -e "${GIMP_BIN:-/Applications/GIMP.app}" ]; then
  echo "  found (skip)"
else
  echo "  NOT FOUND. Required for layered-PSD / script-fu routes."
  echo "  Install GIMP 2.10 from https://www.gimp.org/downloads/ (macOS: the .app bundle)."
  echo "  After installing, export GIMP_BIN=/path/to/gimp-console if non-default."
fi

# 6) Secrets / service URLs -------------------------------------------------
step "configuration (secrets)"
if [ "$NO_SETUP" = "1" ]; then
  echo "  --no-setup: skipping. Run ./setup.sh later to inject API keys/URLs."
elif [ -f "$ASSETS_DST/local_config.json" ]; then
  echo "  local_config.json exists (skip)"
else
  echo "  running setup.sh to inject keys/URLs"
  "$ART_DIR/setup.sh"
fi

echo
echo "install complete. Restart CodeBuddy to load the skills."
echo "Verify with: ~/.venv-art/bin/python $ASSETS_DST/comfyui_generate.py --help"
