# 飞桨生图重生成：安全重试与替换流程

适用场景：广告/VI/课程作业已有可提交 fallback 成品，用户要求“用飞桨/AI Studio 重新生成图片并替换”。

## 原则

1. 不要在 API 成功前删除现有成品。
2. 先把新图生成到临时 retry 目录。
3. 只有全部必需图片成功生成并通过基本文件校验后，才备份并替换 fallback 底图/成品。
4. 如果任一图片失败，保持现有成品不变，并写 blocked report/checkpoint。

## 推荐目录

```text
project/
├── assets/generated_base/                 # 当前底图
├── assets/generated_base_feijiang_retry/  # 本次飞桨临时输出
│   └── YYYYMMDD_HHMMSS/
│       ├── *.png
│       └── meta/*_generation_result.json
├── backups/before_feijiang_regen_*/       # 替换前备份
├── final/
├── source_files/
├── logs/progress.md
├── checkpoint.json
└── reports/feijiang_regeneration_blocked_report.json
```

## Safe retry sequence

1. Run a minimal single-image auth probe first.
2. Generate all required new base images into `assets/generated_base_feijiang_retry/<timestamp>/`.
3. Store each API stdout/stderr/trace in `meta/`, redacting tokens from logs.
4. Validate each output exists and is larger than a trivial threshold (e.g. >10 KB) and can be opened as an image.
5. If all succeed:
   - first copy the complete new retry set to an immutable/preserved backup such as `backups/preserved_feijiang_bases_<retry_ts>_<replace_ts>/` with a `MANIFEST.json`; this protects the AI-generated bases from later overwrites or cleanup and satisfies user requests like “保留底图备份，不要被后续覆盖”;
   - then copy existing `assets/generated_base`, `assets/composited`, `final`, `source_files`, and important reports to `backups/before_feijiang_regen_<timestamp>/`;
   - replace base images from the retry directory (or preserved copy) only after both backups exist;
   - remove old composites/finals only after backup;
   - run composition/PPT/export/quality-check scripts;
   - update checkpoint to `completed` and record both backup directories.
6. If a session is interrupted after all retry images succeed but before replacement:
   - do not regenerate by default; locate the latest retry directory containing all required images;
   - verify each file opens as an image and is non-trivial in size;
   - create the immutable preserved backup before replacing formal files;
   - continue with replacement, recomposition, PPT, reports, and checkpoint update.
7. If any fails:
   - do not replace or delete anything;
   - write `reports/feijiang_regeneration_blocked_report.json`;
   - update checkpoint to `blocked_token_invalid` or `blocked_api_failure`;
   - tell the user exactly what was preserved and what token/API error occurred.

## Auth failure interpretation

- Direct endpoint `https://aistudio.baidu.com/llm/lmapi/v3/images/generations` returning HTTP 401 with `errorCode: 40401` means the token is unauthorized/expired or lacks image-generation permission.
- OpenAI-client path returning `MissingDateHeader` can be a request-signing/infrastructure mismatch; retry once with the direct endpoint to distinguish endpoint/client issues from token auth.
- Never claim generation succeeded unless a local image file was created and verified.
