---
name: gimp-layered-psd-cli
description: Generate layered PSD files headlessly with GIMP 2.10 script-fu from PNG layers (position/scale), plus flattened PNG export and PSD header verification.
---

# GIMP 2.10 headless layered PSD generation

Use when the user needs a layered PSD (poster/illustration deliverable) but Photoshop/GUI automation is unavailable. Verified on macOS GIMP 2.10.38 at `/Applications/GIMP.app/Contents/MacOS/gimp-console`.

## Key facts / pitfalls (verified)

- **Use script-fu (TinyScheme) batch, NOT python-fu-eval.** On this machine python-fu (2.7) hangs when loading PNGs; script-fu is stable.
- `file-psd-save` takes **7 args**: `(file-psd-save RUN-NONINTERACTIVE img drawable filename raw merge 1 0)`. There is no `file-psd-export` in 2.10.
- `file-png-save` takes 10 args: `(file-png-save RUN-NONINTERACTIVE img drawable filename raw 0 9 1 1 1 0 0)`.
- Load PNG via `gimp-file-load` then `gimp-layer-new-from-drawable` into the canvas image. (`gimp-file-layer` does not exist in 2.10.)
- **Never call `gimp-image-delete` on the loaded source images** — in 2.10 it detaches the copied canvas layer from the image (flatten then fails with "no visible layers"). Leaked source images die with the process.
- Layer size procedures are `gimp-drawable-width` / `gimp-drawable-height` (NOT `gimp-drawable-get-width`).
- `gimp-layer-scale` args must be integers → use `(round (* w scale))`.
- Always append a fallback batch `-b "(gimp-quit 0)"`: if the main script errors, the console would otherwise hang in its REPL.
- Set `GIMP_CONFIG`/`GIMP_DATA` to temp dirs (with `gradients/` `brushes/` `patterns/` subdirs) to avoid "writable data folder does not exist" errors.
- Layer argument order = bottom-to-top; `gimp-image-insert-layer img ly 0 -1` appends above.
- PSD save must happen **before** `gimp-image-flatten` (flatten destroys layer structure).

## Usage

```bash
~/.codebuddy/skills/gimp-layered-psd-cli/scripts/assemble_layers.sh \
  <w> <h> <out.psd> <out.png> \
  bg.png \
  subject.png,x,y \
  logo.png,x,y,scale
```

First layer = bottom. Position/scale optional (default 0,0,1.0). Outputs layered PSD + flattened PNG. Runs ~5s for a few layers.

## Verify

```bash
python3 - <<'PY'
from pathlib import Path
import struct
b=Path('<out.psd>').read_bytes()[:26]
assert b[:4]==b'8BPS', 'not PSD'
print({'ver':struct.unpack('>H',b[4:6])[0],'ch':struct.unpack('>H',b[12:14])[0],
       'h':struct.unpack('>I',b[14:18])[0],'w':struct.unpack('>I',b[18:22])[0]})
PY
```

Use `ViewImage` on the flattened PNG for visual QA.

## When to prefer compositor CLI instead

Text-free simple compositing (paste RGBA over background at position) can use `compositor composite` directly (faster, no PSD). Use this skill when the deliverable must be an editable layered PSD.
