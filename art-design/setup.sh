#!/usr/bin/env bash
# setup.sh — inject API keys and service URLs for the art-design framework.
#
# Run ONCE after install.sh (or standalone). Nothing in this script is ever
# committed to the repository. All secrets / URLs are written to local,
# 600-permission files under ~/.codebuddy/assets/art-design/ and are never
# placed into repo files, logs, or commit artifacts.
#
# What it collects:
#   1. ComfyUI base URL        -> local_config.json["comfyui_base"]
#   2. ComfyUI API key         -> comfyui_1238.key (the X-API-Key header)
#   3. Optional LLM endpoints  -> local_config.json["llm_endpoints"] (for visual QA)
#
# The framework's Python scripts (comfyui_generate.py, visual_quality_assessor.py)
# read local_config.json at runtime; they contain NO hardcoded URLs or keys.
set -euo pipefail

ASSET_DIR="$HOME/.codebuddy/assets/art-design"
mkdir -p "$ASSET_DIR"
chmod 700 "$ASSET_DIR"

CONFIG="$ASSET_DIR/local_config.json"
KEY_FILE="$ASSET_DIR/comfyui_1238.key"
TMP_EP="$(mktemp)"; chmod 600 "$TMP_EP"

PY="${PYTHON:-$(command -v python3 || true)}"
if [ -z "$PY" ] && [ -x "$HOME/.venv-art/bin/python" ]; then PY="$HOME/.venv-art/bin/python"; fi
if [ -z "$PY" ]; then echo "error: python3 not found (install it or create ~/.venv-art)" >&2; exit 1; fi

echo "=== art-design framework setup ==="
echo "Secrets are stored locally (chmod 600) only; nothing is written to the repo."
echo

# 1) ComfyUI base URL
read -r -p "ComfyUI base URL (e.g. http://host:1238): " COMFYUI_BASE
while [ -z "${COMFYUI_BASE:-}" ]; do
  read -r -p "ComfyUI base URL is required (e.g. http://host:1238): " COMFYUI_BASE
done

# 2) ComfyUI API key (hidden input)
read -r -s -p "ComfyUI API key (X-API-Key, input hidden): " COMFYUI_KEY
echo
while [ -z "${COMFYUI_KEY:-}" ]; do
  read -r -s -p "ComfyUI API key is required: " COMFYUI_KEY
  echo
done
printf '%s' "$COMFYUI_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"
echo "  saved key -> $KEY_FILE (600)"

# 3) Optional LLM endpoints for subjective visual QA
echo
echo "Optional: LLM endpoints for visual-quality subjective scoring."
echo "Enter URL + API key pairs; leave URL empty to finish."
while true; do
  read -r -p "  LLM endpoint URL (empty to finish): " U
  [ -z "$U" ] && break
  read -r -s -p "    API key for $U (hidden, empty if none): " K
  echo
  printf '%s\t%s\n' "$U" "$K" >> "$TMP_EP"
done

# Write local_config.json
"$PY" - "$CONFIG" "$COMFYUI_BASE" "$TMP_EP" <<'PY'
import json, sys, os
cfg_path, base, tmp_ep = sys.argv[1], sys.argv[2], sys.argv[3]
eps = []
with open(tmp_ep) as f:
    for line in f:
        line = line.rstrip("\n")
        if not line.strip():
            continue
        u, k = line.split("\t", 1)
        eps.append({"url": u, "apiKey": k, "id": u, "supportsImages": True})
cfg = {
    "comfyui_base": base.rstrip("/"),
    "comfyui_key_path": os.path.expanduser("~") + "/.codebuddy/assets/art-design/comfyui_1238.key",
    "llm_endpoints": eps,
}
with open(cfg_path, "w") as f:
    json.dump(cfg, f, indent=2, ensure_ascii=False)
PY
chmod 600 "$CONFIG"
rm -f "$TMP_EP"
echo "  saved config -> $CONFIG (600)"
echo
echo "setup complete. The framework now has its service URLs and keys configured locally."
