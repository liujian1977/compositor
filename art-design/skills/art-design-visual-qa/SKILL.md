---
name: art-design-visual-qa
description: 视觉质量评估技能，用三路评估（ViewImage 目检、多模态服务打分、compositor/PIL 客观指标）做三维质量评分并给出修复建议
---

# Art Design Visual QA (视觉质量评估)

## Overview

统一工作流的**视觉质量评估子技能**。对生成/合成图像做三维评分：图像质量（客观）、风格一致性、美学表现，并输出可操作修复建议。

## 三路评估路由

| 路线 | 工具 | 适用 |
|---|---|---|
| A. 快速目检 | `ViewImage`（带自包含 query） | 每轮迭代后的廉价检查：构图、明显缺陷、文字可读性 |
| B. 模型评分 | `scripts/visual_quality_assessor.py` | 需要量化分数（pass/fail、迭代对比、最终验收） |
| C. 结构校验 | compositor CLI + PIL | 尺寸/alpha/对齐等确定性检查，不依赖模型 |

### B 路线用法（主要量化手段）

```bash
~/.venv-art/bin/python ~/.codebuddy/skills/art-design-visual-qa/scripts/visual_quality_assessor.py \
  <image.png> --style "<目标风格>" --use-case "<用途>"
```

- 端点与密钥从 `~/.codebuddy/models.json` 读取（选取 `supportsImages` 的自定义模型条目），**不要在技能或脚本中硬编码 key**
- 图像自动降采样 ≤512px、JPEG q85 后 base64
- 输出 JSON：`overall_score`、`dimensions{image_quality, style_consistency, aesthetic_appeal}`、`objective_metrics`、`defects[]`、`improvement_suggestions[]`、`passed`
- 权重：客观 ~25% + 主观 ~75%

### C 路线（确定性结构检查）

```bash
COMPOSITOR=${COMPOSITOR_BIN:-$HOME/.codebuddy/bin/compositor}
$COMPOSITOR face-detect --image <img>        # 人脸存在性/数量
$COMPOSITOR pose-estimate --image <img>      # 姿态关键点（人物类任务）
# PIL: 尺寸、alpha 通道、边框伪影
~/.venv-art/bin/python -c "from PIL import Image; im=Image.open('<img>'); print(im.size, im.mode)"
```

YOLO 目标清单可用 `semantic-gimp-artistic-stylization/scripts/object_detection.py`（COCO 类，艺术图常检不到物体，0 检出≠失败）。

## 评分与通过标准

- 通过：overall ≥ 80 且 style_consistency ≥ 75 且无"高"严重缺陷
- 不达标：按 defects 修最大缺陷，每轮只修一个；连续 2 轮同一缺陷无改善 → 改用确定性后处理（compositor inpaint/face-swap/composite）而不是继续重生成
- 迭代上限 3–5 轮

## 调用时机

1. 原图分析：参考图特征提取（配合 ViewImage）
2. 生成后评估：B 路线量化打分
3. 自修正循环：defects → 修复动作映射

## 注意事项

1. 多模态服务返回非 JSON 时脚本会报错——重跑一次，仍失败则回退 A 路线目检
2. 客观指标（sharpness/saturation）对扁平插画、故意留白风格会偏低，以主观维度为主裁决
3. 评估用的模型与生成用的 ImageGen 不同源，分数只做相对参考

## 参考文件

- `references/quality_standards.md` — 三维质量标准定义
