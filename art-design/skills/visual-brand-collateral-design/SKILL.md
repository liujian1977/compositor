---
name: visual-brand-collateral-design
description: Use when creating brand, advertising, poster, VI/manual, or marketing collateral with CodeBuddy ImageGen + PIL/compositor workflows. Covers style consultation, prompt engineering, print specs, logo-accurate mockups, PPT/manual assembly, and format-compliant deliverables.
---

# Visual Brand & Collateral Design

## Overview

AI-assisted visual brand collateral: advertising posters, multi-format ad campaigns, VI/brand manuals, branded mockups, PPT-integrated visual identity. Core class: **brand/application design with generated or composited images** — choose the right style, preserve brand elements, produce format-compliant assets, verify deliverables.

Companion skills: `art-design-unified-workflow` (general task flow), `art-design-domain-knowledge` (style/palette theory via knowledge.db), `art-design-visual-qa` (delivery QA), `artistic-text-generation` (CJK typography via PIL), `gimp-layered-psd-cli` (layered PSD export).

## When to Use

- Advertising/poster design for courses, campaigns, events, brands, cities, culture themes
- Multi-format ad sets: newspaper, magazine, outdoor poster, POP/in-store
- VI/Visual Identity manuals, brand books, style guides, application systems
- Branded mockups: business cards, letterheads, envelopes, certificates, posters, uniforms, tote bags, signage
- Regenerating brand application images where logo/badge accuracy matters
- Inserting generated collateral into PPT decks/manuals with precise layout

Not for: web UI/landing pages; pure diagrams/infographics (use `baoyu-infographic`); generic image generation without brand constraints (use ImageGen directly via `art-design-unified-workflow`).

## Core Workflow

```
brief intake → asset/style verification → workflow choice → prompt/template review → generation/composition → format/PPT integration → verification
```

### 1. Intake: clarify medium, brand assets, acceptance bar

Use **AskUserQuestion** (not guesswork) to confirm:
- Target medium: print poster, ad campaign, VI manual, PPT page, web/social asset
- Required formats: A4/A5, newspaper, magazine, outdoor, POP, PPT-optimized sizes
- Brand assets: official logo/badge files, color codes, type, motto/tagline, existing manual pages
- Style direction: artistic illustration, 新中式, geometric, oil painting, watercolor, photo-realistic
- Accuracy vs realism: exact logo fidelity vs material realism

**Default for poster/ad work:** prefer artistic styles (illustration, painting, geometric, 新中式) over photo-realistic unless explicitly requested. Add `非照片写实` / `avoid: photorealistic photo` to prompts when design intentionality matters.

### 2. Workflow choice: PIL/compositor vs AI generation

| Scenario | Recommended approach | Why |
|---|---|---|
| Official logo/badge accuracy critical | **PIL composition with real logo assets** (`templates/pil_vi_mockup_generator.py`) | 100% logo fidelity; fast; stable; PPT-friendly |
| User says generated logo is wrong | **Stop ImageGen retries; switch to PIL** | Prompt tweaks still distort institutional marks |
| Realistic texture/material, tolerate variation | ImageGen **img2img** (image1 + moderate input_fidelity) | Better surfaces; check results with visual-qa |
| Hypothetical brand, no official assets | ImageGen txt2img | Creative interpretation acceptable |
| Baidu AI Studio / 飞桨 route | **HOLD — not available in CodeBuddy** | ERNIE txt2img-only; token placeholders in templates kept for reference only |

Rule from VI work: if the user says a generated badge/logo is wrong, do **not** keep rewriting prompt descriptions. Locate the official logo file and compose it with PIL/compositor.

### 3. Verify brand assets before generating

```bash
find /path/to/project -iname '*logo*' -o -iname '*badge*' -o -iname '*校徽*'
```

Verify shape, colors, text, motto, distinctive marks; exact brand color codes; CN/EN names and capitalization; whether alpha compositing is needed. Never use generic descriptions like "red circular clock tower" when an official asset exists. ViewImage the asset to confirm.

### 4. Style consultation and prompt review

For multi-asset projects write `work/prompts_for_review.md` first — the user corrects terminology once before generation.

Poster/ad prompts include: style first (e.g. `新中式插画风格`), composition/spatial layout, key elements with style descriptors, color palette + brand colors, transition treatment, output dimensions. ImageGen size mapping: 1:1→1024x1024, 16:9→1536x1024, 9:16→1024x1536; final print sizes are achieved by deterministic upscale/crop in PIL, not by diffusion at print resolution. Announce ImageGen credit cost (5–10/image) before batch calls.

VI prompts include: official logo description only after asset verification (or use PIL), brand name in all required languages, exact motto text, material/usage context, brand colors with hex, application dimensions.

Query `art-design-domain-knowledge` (sqlite3 knowledge.db, domains `poster_plan_*`/`logo_*`/`vi_*`) for style theory before writing prompts.

## Poster and Advertising Design

Style options to propose (see `references/ad-style-lessons.md`):

| Style | Best for | Characteristics |
|---|---|---|
| 新中式插画 | Traditional-modern fusion | 工笔线条 + 扁平色块, 墨黑/朱砂红/石青, 留白 |
| 半抽象油画 | Cultural/high-art campaigns | 厚笔触, color depth, between figurative and abstract |
| 几何简约 | Modern/tech brand | Color blocks, minimalism |
| 水彩 | Travel/lifestyle | Transparent, airy |
| 霓虹发光 | Youth/nightlife | Fluorescent, glow |

Edge transitions: specify width, technique, direction, negative constraint — not vague "自然过渡":

```text
过渡处理：沿对角线中部设置"边缘渐变"过渡带（约150–200像素），
从{冷调}向{暖调}自然平滑过渡，避免生硬分割线。
可用半透明色带、光晕或纹理叠加以实现边缘渐变。
```

Print specs (`references/ad-formats.md`): A4 2480×3508@300dpi / 1653×2339@200dpi; A5 1748×2480@300dpi. ImageGen outputs are art bases; compose to print size with PIL (cover+crop, aspect-preserving) and typeset CJK text with `artistic-text-generation` — never rely on diffusion for Chinese text.

## VI / Brand Manual and Mockup Design

Standard VI applications: 名片, 信纸信封, 证书, 海报, 录取通知书, 官网Banner/数字媒体, 服装, 手提袋, 导视/旗帜.

**PIL composition path (preferred for logo-critical work)** — start from `templates/pil_vi_mockup_generator.py`:
- PNG logo with transparency; high-quality resampling
- PPT-optimized dimensions if output only appears in a deck: 名片 1050×600, 信纸 1050×1480, 海报 740×1050, 证书 1050×740
- Save generation manifest/results JSON; ViewImage-verify logo placement in every mockup
- Compose AI base art + logo + text with `compositor composite` (see `art-design-gimp-processing` backend table) or PIL

**ImageGen txt2img path** — only for non-critical or hypothetical brand elements. For batch generation adapt `templates/multi-format-campaign.py` structure (manifest + meta JSON) but replace the API call with the ImageGen tool or the ComfyUI :1238 client (`art-design-unified-workflow`); `templates/vi-batch-generation-template.py` is Baidu-specific and **HOLD** (token placeholder only, route unavailable).

**PPT/manual integration**: explicit `Inches()`/`Cm()` positions; document slide index vs visible page; use `RGBColor` not `RgbColor`; open the saved pptx to verify.

## Output Structure

All tasks under `~/.codebuddy/projects/Users-<username>/creative/art/<task_name>/`:

```
├── final/assets/        # final PNG/JPG
├── candidates/          # unselected generations
├── prompts/             # prompt versions (prompt files first)
├── source_layers/       # layered PNGs + PSD
├── analysis/            # visual-qa reports
├── temp/                # experiments
└── work/                # scripts, plans, prompts_for_review.md, brand_mockups/
```

Ad campaign flat variant: `assets/` (MANIFEST.json + *_ad_meta.json + *_final.png), `newspaper_ad/`, `magazine_ad/`, `poster_design/`, `pop_ad/`.

## Support Files

- `references/ad-formats.md` — format specs and dimension calculations
- `references/ad-style-lessons.md` — style feedback patterns, transitions, poster prompt lessons
- `references/shanghai-ad-coursework.md` — 上海开放大学《广告设计》作业 rubric, A4 200dpi specs
- `references/ad-layout-aspect-text-qa.md` — aspect-safe ad composition, CJK shrink/wrap fitting, focused QA
- `references/ad-layout-final-qa-cta-qr.md` — final delivery QA: QR/CTA pairing, crop-focused review
- `references/ad-typography-strict-delivery-qa.md` — strict legibility loop with crop evidence
- `references/kunqu-ad-coursework-prompts.md` / `checkpointed-ad-campaign-pipeline.md` — campaign examples
- `references/suda-vi-session-learning.md` — VI mockup + PPT insertion lessons
- `references/baidu-aistudio-img2img-limitations.md` — historical limitation notes (route HOLD)
- `references/feijiang-regeneration-safe-retry.md` — safe retry ordering (adapt: all ImageGen replacements succeed before swapping finals)
- `templates/pil_vi_mockup_generator.py` — PIL mockup template (run via `~/.venv-art/bin/python`)
- `templates/multi-format-campaign.py` — campaign manifest structure (API section HOLD)
- `templates/ads-manifest.json` — campaign manifest template

## Common Pitfalls

1. **Defaulting to photorealism** — ask/infer style first; add `非照片写实` / `avoid: photorealistic`.
2. **Prompting an official logo into existence** — use the real asset + PIL.
3. **Blank VI templates** — users expect logo, text, color, application context.
4. **Skipping prompt review for multi-asset projects** — write prompts_for_review.md first.
5. **Ignoring print/PPT target size** — PPT-only deliverables don't need 4K.
6. **Distorting AI base art during layout** — no direct resize() squaring→tall; use cover+crop or contain+margins; text panels/bands instead of semi-opaque boxes over the subject.
7. **Vague transition instructions** — specify width, direction, blend technique.
8. **Diffusion for Chinese text** — always PIL typesetting (artistic-text-generation).
9. **PPT off-by-one / python-pptx casing** — verify after saving.

## Verification Checklist

- [ ] Brand/logo assets located and ViewImage-verified
- [ ] Workflow selected: PIL / img2img / txt2img
- [ ] prompts_for_review.md reviewed for multi-asset projects
- [ ] Output dimensions/DPI match target medium
- [ ] Logo/text/color fidelity checked in every mockup
- [ ] Manifest/results JSON saved
- [ ] `art-design-visual-qa` passed on final deliverables
- [ ] Files copied into delivery directory
