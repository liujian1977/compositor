---
name: semantic-gimp-artistic-stylization
description: Use when transforming an original image into an artistic version with reference preservation, semantic object/position analysis (YOLO), GIMP script-fu selection/channel/color scripting, and iterative downsampled comparison. Includes copy-study/临摹 and YOLO-protected style transfer (照片转Q版/油画等) as constrained cases.
---

# Semantic GIMP Artistic Stylization

把原图转化为艺术化版本、同时保持结构。合并了原 `gimp-smart-style-transfer`（YOLO 检测 + 参数化风格迁移）。

核心方法：
1. **中低层语义识别** — YOLO 对象框 + 区域颜色/明度/边缘统计
2. **高层语义解读** — 文化/情绪/叙事/时代风格
3. **数值化分析** — bbox、局部调色板、亮度图、边缘密度
4. **GIMP script-fu 操作生成** — 选择/通道/曲线/色阶/色相饱和/posterize/纹理，保护区隔离
5. **A/B/C 迭代**：A 生成脚本 → B 降采样对比+判定 → C 修订重跑

## 何时用 / 不用

用：给原图做艺术化处理且需保持结构；区域级保护（脸/文字/logo/主体）；临摹；需要可重复脚本与分层 PSD。
不用：纯文生图（走 ImageGen）；精确矢量复刻（走确定性合成）；简单裁剪缩放。

## Phase 1 — 目标定义

```yaml
input_image: <path>
output_goal: 临摹/浮世绘/水墨/Q版/油画/vintage...
preserve: [构图, 主体位置, 脸/文字, 明度结构, 局部色彩关系]
allowed_changes: [纸纹, 笔触, 线宽, 边缘粗糙度, 轻微色温偏移]
forbidden_changes: [移动物体, 改变身份, 文字不可读, 阴影死黑, 保护区全局色偏]
outputs: [png/jpg, layered psd]
```

临摹优先级：轮廓/布局 > 明度结构 > 局部色彩关系 > 仅表面风格。

## Phase 2 — YOLO + 区域分析

```bash
# 对象检测（权重已固化，无需下载）
~/.venv-art/bin/python ~/.codebuddy/skills/semantic-gimp-artistic-stylization/scripts/object_detection.py <image> [conf]
# → JSON: class_name/bbox{ x1,y1,x2,y2,center } per object（COCO 类；艺术图 0 检出≠失败，用 ViewImage 补语义表）

# 区域统计（PIL）
~/.venv-art/bin/python - <<'PY'
from PIL import Image, ImageStat, ImageFilter, ImageOps
import numpy as np
im = Image.open('<path>').convert('RGB')
for name, box in {'subject':(x1,y1,x2,y2)}.items():
    crop = im.crop(box); gray = ImageOps.grayscale(crop)
    edges = gray.filter(ImageFilter.FIND_EDGES)
    print(name, 'mean_rgb', ImageStat.Stat(crop).mean,
          'lum', ImageStat.Stat(gray).mean[0],
          'edge_density', np.array(edges).mean()/255)
PY
```

建立对象/区域表（id、bbox、mask 方法、保护规则、风险），坐标用最终尺寸像素值。

## Phase 3 — 高层语义解读

先写短解读：文化/时代/风格、应保留或改变的情绪、叙事、禁止改变项。它决定操作（例如浮世绘临摹：保留浪的剪影与船位、纸纹局部叠加而非全局模糊、船保持木色赭色）。

## Phase 4 — GIMP script-fu 操作脚本（A）

运行方式（必须带兜底 quit）：

```bash
GIMP_CONFIG=/tmp/gc GIMP_DATA=/tmp/gd /Applications/GIMP.app/Contents/MacOS/gimp-console \
  -i -b "$SCRIPT" -b "(gimp-quit 0)" </dev/null
```

关键操作（2.10 script-fu）：

```scheme
;; 保护区隔离：复制 → add-alpha → 选区 → invert → clear
(src (car (gimp-file-load RUN-NONINTERACTIVE p p)))
(ly (car (gimp-layer-new-from-drawable (car (gimp-image-get-active-drawable src)) img)))
(gimp-layer-add-alpha ly)          ; 必须先加 alpha！
(gimp-image-select-rectangle img CHANNEL-OP-REPLACE x y w h)
(gimp-selection-feather img 10)
(gimp-selection-invert img)
(gimp-drawable-edit-clear ly)
(gimp-selection-none img)

;; 轻度全局风格（在副本上）
(gimp-drawable-posterize drawable 36)
(gimp-hue-saturation drawable HUE-RANGE-ALL 0 -7 0)
(gimp-brightness-contrast drawable 5 -3)
```

风格参数速查（原 smart_style_transfer 语义）：
- Q版/卡通：低模糊、噪点≈0、强锐化、风格不透明度 ~0.6
- 油画：模糊 5、噪点 5、opacity ~0.7、叠画布纹理层（pattern overlay）
- 素描：去饱和 + posterize + 边缘层 screen 叠加

## Phase 5 — 对比判定（B）

- 降采样联系表：原图/上一版/当前（PIL 拼接）
- 确定性指标（降采样后）：直方图相似度、明度相似度、边缘 IoU、phash；保护区局部色差
- 临摹类：结构/明度/色彩分 ≥85 才算稳
- 用 `art-design-visual-qa` 三路评估 + ViewImage 目检文化/情绪要求

## Phase 6 — 迭代（C）

| 失败 | 修订 |
|---|---|
| 保护区被染色 | 加保护图层；缩小全局饱和度作用于该区 |
| 文字/标题形变 | 用原文字裁剪层+alpha 蒙版+淡纸洗，不凭空造笔画 |
| 画面发灰 | clear 前没 add-alpha；减少白色叠加；查图层不透明度 |
| 滤镜感过重 | 降 posterize/噪点；加原图导出的轮廓 |
| 不够艺术 | 加表面层（颗粒/笔触/边缘粗糙），不动物体 |
| 临摹太机械 | 保结构，只轻变纸纹/笔触/边缘/色温 |

## 输出目录

统一工作流任务目录 `~/.codebuddy/projects/Users-<username>/creative/art/<task>/`：final/ candidates/ prompts/ source_layers/ analysis/ temp/（GIMP 脚本与调试产物放 temp/）。

## Pitfalls

1. 全局滤镜思维——风格要按语义区域施加
2. 没有区域数值统计，保护区必然漂移
3. clear 前忘记 add-alpha → 区域变不透明底色
4. 只评整图分，不查关键裁片与保护区色差
5. 临摹≠重新诠释：先保结构，再个性化表面
6. 交付目录不放过程文件
