# Checkpointed ad-campaign production pipeline

Use this when an advertising/coursework job asks for multiple generated assets plus final deliverables, and the user wants checkpoint-based recovery and progress feedback.

## Directory pattern

Create the project under the requested work directory:

```text
project/
├── checkpoint.json
├── checkpoints/checkpoint.json
├── logs/progress.md
├── logs/<run>.console.log
├── scripts/run_assignment_pipeline.py
├── prompts/
├── assets/generated_base/
├── assets/composited/
├── final/
├── source_files/
└── reports/
```

Write both primary and backup checkpoints after every phase. Keep `logs/progress.md` human-readable and append one timestamped line per step.

## Steps to encode in checkpoint

Typical multi-format ad campaign steps:

1. `init_project_structure`
2. `verify_dependencies`
3. `load_prompts`
4. `generate_base_images`
5. `compose_layouts_with_text`
6. `export_final_jpg`
7. `create_editable_source_files`
8. `quality_check`
9. `write_final_report`

Each asset should track at least:

```json
{
  "status": "pending|base_ready|final_ready",
  "base_image": "...",
  "final_png": "...",
  "final_jpg": "...",
  "source_file": "..."
}
```

## Progress feedback pattern

For every major operation, log and print lines like:

```text
- 2026-06-12T01:08:08 STEP compose_layouts_with_text/报纸广告: 开始后期文字排版
- 2026-06-12T01:08:08 STEP export_final_jpg/报纸广告: 已导出 PNG/JPG：01_newspaper_ad_final.png, 01_newspaper_ad_final.jpg
```

Launch bounded long runs with stdout mirrored to a console log and completion notification:

```bash
python3 scripts/run_assignment_pipeline.py 2>&1 | tee logs/run_assignment_pipeline.console.log
```

After the background process completes, verify actual deliverables: checkpoint status, every expected file, file sizes, and image dimensions/DPI.

## Image generation fallback

When diffusion generation fails in a multi-deliverable ad campaign, do not abandon the pipeline if the user asked for completed deliverables. Record the generation error in metadata/logs, then create a deterministic fallback base image with PIL/Pillow:

- Use the approved palette exactly.
- Preserve the required medium dimensions and DPI.
- Reserve layout zones for title/body/QR/information.
- Use abstract curves, geometric grids, paper texture, ink washes, and other style-appropriate vector-like elements.

This fallback is acceptable as a recovery path for coursework mockups/source files, but report clearly that AI generation failed and a PIL/vector fallback was used.

## Deliverables to verify

For each format:

- AI/generated or fallback base PNG
- composited PNG with typography
- final JPG in the required dimensions/DPI
- editable source file (often PPTX if PSD/AI is not available)
- prompt text and/or creation notes
- quality check report
- final delivery report
