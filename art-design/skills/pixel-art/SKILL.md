---
name: pixel-art
description: "Pixel art w/ era palettes (NES, Game Boy, PICO-8). Convert images to retro pixel art via PIL; animation route requires ffmpeg (not installed on this machine)."
---

# Pixel Art

Convert any image into retro pixel art (Floyd-Steinberg dithering, hardware palettes). Animation into MP4/GIF is **available only after installing ffmpeg** — see Dependencies.

Scripts in this skill directory (`~/.codebuddy/skills/pixel-art/scripts/`):

- `pixel_art.py` — photo → pixel-art PNG (PIL-only, works now)
- `pixel_art_video.py` — pixel-art PNG → animated MP4 (+ optional GIF), **requires ffmpeg**
- `palettes.py` — 28 named palettes

Run everything with `~/.venv-art/bin/python` (Pillow installed there).

## When to Use

- Retro pixel art from a source image; NES / Game Boy / PICO-8 / C64 / arcade / SNES styling
- Posters, album covers, social posts, sprites, characters, avatars
- (Video only if ffmpeg present) short looping animation: rain, night sky, snow, embers

## Workflow

Confirm style before generating — presets differ a lot and regeneration is costly.

1. **Offer a style** — use **AskUserQuestion** with 4 representative presets picked from the request (don't dump all 14). Default menu when intent unclear: arcade / nes / gameboy / snes. If the user already named an era ("80s arcade", "Gameboy"), skip the question and use the matching preset.
2. **Offer animation (optional)** — only ask if ffmpeg is available (check `which ffmpeg` first); otherwise state the video route is unavailable and offer PNG only.
3. **Generate** — run `pixel_art.py` first; chain `pixel_art_video.py` only if animation was requested and ffmpeg exists.

Ask at most twice per turn (style, then scene). If the user specified style+scene in their message, ask zero times.

Source images: user files, ImageGen output (announce credits; recommend 1:1 1024x1024 base), or `compositor` results. Output to `~/.codebuddy/projects/Users-<username>/creative/art/<task>/`.

## Preset Catalog

| Preset | Era | Palette | Block | Best for |
|--------|-----|---------|-------|----------|
| `arcade` | 80s arcade | adaptive 16 | 8px | Bold posters, hero art |
| `snes` | 16-bit | adaptive 32 | 4px | Characters, detailed scenes |
| `nes` | 8-bit | NES (54) | 8px | True NES look |
| `gameboy` | DMG handheld | 4 green shades | 8px | Monochrome Game Boy |
| `gameboy_pocket` | Pocket handheld | 4 grey shades | 8px | Mono GB Pocket |
| `pico8` | PICO-8 | 16 fixed | 6px | Fantasy-console look |
| `c64` | Commodore 64 | 16 fixed | 8px | 8-bit home computer |
| `apple2` | Apple II hi-res | 6 fixed | 10px | Extreme retro, 6 colors |
| `teletext` | BBC Teletext | 8 pure | 10px | Chunky primary colors |
| `mspaint` | Windows MS Paint | 24 fixed | 8px | Nostalgic desktop |
| `mono_green` | CRT phosphor | 2 green | 6px | Terminal/CRT aesthetic |
| `mono_amber` | CRT amber | 2 amber | 6px | Amber monitor look |
| `neon` | Cyberpunk | 10 neons | 6px | Vaporwave/cyber |
| `pastel` | Soft pastel | 10 pastels | 6px | Kawaii / gentle |

Palette keys are case-sensitive (`"NES"`, `"PICO_8"`, `"GAMEBOY_ORIGINAL"`). Any preset can be overridden; full palette list in `references/palettes.md`.

## Scene Catalog (video only)

`night` (stars+fireflies) · `dusk` · `tavern` · `indoor` · `urban` (rain+neon) · `nature` · `magic` · `storm` · `underwater` · `fire` (embers) · `snow` · `desert` (heat shimmer)

## Invocation

```bash
PY=~/.venv-art/bin/python
S=~/.codebuddy/skills/pixel-art/scripts

$PY $S/pixel_art.py in.jpg out.png --preset gameboy
$PY $S/pixel_art.py in.jpg out.png --preset snes --palette PICO_8 --block 6

# video — only when ffmpeg is on PATH
$PY $S/pixel_art_video.py out.png out.mp4 --scene night --duration 6 --gif
```

Import route (from any script): `sys.path.insert(0, str(Path.home()/".codebuddy/skills/pixel-art/scripts"))`, then `from pixel_art import pixel_art`.

## Pipeline Rationale

Pixel conversion: contrast/color/sharpness boost (stronger for smaller palettes) → posterize → downscale by `block` with NEAREST → quantize with Floyd-Steinberg against adaptive or hardware palette → upscale NEAREST. Quantizing after downscale keeps dithering aligned with the final pixel grid.

Video overlay: static base frame per tick + stateless particle effects; ffmpeg `libx264 -pix_fmt yuv420p -crf 18`; GIF via palettegen/paletteuse.

## Dependencies

- Python 3.9+ with Pillow — present in `~/.venv-art` ✔
- ffmpeg on PATH — **not installed on this machine**; `pixel_art_video.py` raises without it. Optional install: `brew install ffmpeg` (confirm with user before installing).

## Pitfalls

- Palette keys case-sensitive; `block`/`palette` must be positive ints.
- Sources <100px wide collapse under 8–10px blocks — upscale the source first.
- Particle counts tuned for ~640x480; on large canvases re-run with another seed for density.
- `mono_green`/`mono_amber` force desaturation; keeping chroma causes striping on smooth regions.
- At most 2 AskUserQuestion rounds (style, scene).

## Verification

- PNG exists at output path; pixel blocks visible at preset block size
- Color count matches preset (`Image.open(p).getcolors()`) or ViewImage check
- Video (if produced): non-zero MP4, `ffprobe` opens it
- Final deliverable QA: `art-design-visual-qa` for poster/asset use cases

## Attribution

Hardware palettes and animation loops ported from pixel-art-studio (MIT) — see `ATTRIBUTION.md`.
