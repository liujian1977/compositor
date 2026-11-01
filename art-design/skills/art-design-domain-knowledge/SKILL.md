---
name: art-design-domain-knowledge
description: 领域知识管理技能，提供 LOGO/海报/插画/VI/UI-UX 等设计领域的理论、规范、配色方案与风格参考，通过 sqlite3 查询本地知识库 knowledge.db
---

# Art Design Domain Knowledge (领域知识管理)

## Overview

艺术设计统一工作流的**领域知识管理子技能**。知识主体存放在本地 SQLite 知识库，按需查询（渐进披露，不要一次拉取大量条目）。

## 知识库位置与查询方式

知识库（只读）：`~/.codebuddy/assets/art-design/knowledge.db`

查询一律用：

```bash
sqlite3 -readonly ~/.codebuddy/assets/art-design/knowledge.db "<SQL>"
```

表结构 `knowledge_items`：

| 字段 | 说明 |
|---|---|
| id | 主键 |
| created_at | 生成时间 |
| domain | 领域名（见下方 domain 清单） |
| step | 工作流阶段：clarify / plan_analysis / plan_strategy / plan_tech / execute_generate / execute_process / evaluate / recognize / intent_parse / analyze_material / source_material |
| step_goal | 该条目要解决的问题 |
| depth | 深度：overview / detail / advanced |
| query_pattern | 原始查询语句 |
| content | JSON 正文（知识内容） |
| evidence | 来源原文引用 |
| quality_score | 85–98（均值 ~92.6） |
| source_urls | 来源 URL |

### 查询模板（按阶段渐进披露）

```sql
-- 需求分析阶段：某领域的 overview 级知识
SELECT step_goal, content FROM knowledge_items
WHERE domain='poster' AND step='plan_analysis' AND depth='overview'
ORDER BY quality_score DESC LIMIT 3;

-- 策略制定：风格与构图建议
SELECT step_goal, content, evidence FROM knowledge_items
WHERE domain='poster_layout' AND step='plan_strategy'
ORDER BY quality_score DESC LIMIT 3;

-- 技术选择：执行阶段技术方案（含 img2img 精专领域）
SELECT step_goal, content FROM knowledge_items
WHERE domain LIKE 'img2img_%' AND step='plan_tech'
ORDER BY quality_score DESC LIMIT 3;

-- 质量评估：evaluate 阶段标准
SELECT step_goal, content FROM knowledge_items
WHERE step='evaluate' AND domain IN ('poster','illustration')
ORDER BY quality_score DESC LIMIT 3;

-- 全文检索兜底（query_pattern 索引）
SELECT domain, step, step_goal FROM knowledge_items
WHERE query_pattern LIKE '%配色%' LIMIT 10;
```

注意：`content` 是 JSON 字符串，取回后按需解析；单次查询 LIMIT ≤ 5，避免上下文膨胀。

### domain 清单（65 个）

通用 20 个：`poster` `poster_layout` `illustration` `children_book` `children_book_illustration` `logo_design` `brand_design` `typography` `editorial` `packaging` `photo_editing` `photography` `web_design` `app_design` `ui_design` `motion_graphics` `3d_modeling` `color_psychology` `ethnic_cultural_visual_language` `gimp_style_transfer`

图生图/精专 45 个（前缀 `img2img_*`）：analyze_*（材质/构图/色彩/光影/风格描述等 11 个）、controlnet_*（canny/depth/openpose/scribble）、ipadapter_*、inpainting/outpainting、recognition_*（yolo/sam2/rembg/dwpose/face_mesh/lineart 等）、img2img_denoise_control、upscale_esrgan、pil_precision_compositing、gimp_mask_to_comfy、gimp_python_fu_batch 等。

> 注意：`img2img_controlnet_*` / `img2img_ipadapter_*` 等 ComfyUI 专属知识仅作背景参考；当前 ComfyUI 后端 (:1238) 客户端仅支持 txt2img 直连工作流，ControlNet/IPAdapter 节点图尚未封装，可执行的实现路径以 compositor CLI 与 GIMP script-fu 为准。

## 静态参考库（UI/UX）

位于本技能 `references/`（来源 UI UX Pro Max）：

- `ui-ux-pro-max/ui-ux-styles-reference.md` — 84 种 UI 风格（AI prompt 关键词、CSS 规范、色彩方案）
- `ui-ux-pro-max/ui-ux-color-reference.md` — 192 种产品类型配色（跨领域可参考）
- `ui-ux-pro-max/ui-ux-typography-reference.md` — 74 种字体搭配
- `ui-ux-pro-max/ux-guidelines-reference.md` — 99 条 UX 最佳实践与反模式
- `ui-ux-pro-max/ui-reasoning-reference.md` — 161 条 UI 决策规则
- `ui-ux-pro-max/charts-reference.md` — 25 种图表类型选择指南（信息图参考）
- `ui-ux-pro-max/motion-patterns-reference.md` — 16 种动效模式

入口索引：`references/UI-UX-REFERENCE-INDEX.md`。UI/UX 类任务先读索引再按需打开单个文件。

## 跨领域配色速查

任何设计领域均可参考 UI 配色（节选）：

| 场景 | 配色 |
|---|---|
| SaaS | #2563EB + #EA580C 对比 CTA |
| 奢华高端 | #1B2A4A + #D4AF37 金 + 米白 |
| 健康养生 | #2D9C6F + 暖白 + #E8A87C |
| 金融银行 | #0B132B + 金 + 白 |
| 餐饮外卖 | #FF6B35 + #E63946 + #FFD166 |
| 游戏 | 黑底 + #00FF88/#BF00FF 霓虹 |

色彩心理：红=热情紧迫、蓝=信任专业、绿=自然成长、黄=活力警告、紫=创意奢华、橙=友好年轻、黑=权威优雅、白=简洁高端。

## 质量评估标准

- 技术：印刷 ≥300DPI / Web ≥72DPI；LOGO 矢量、海报分层 PSD；Web sRGB、印刷 CMYK
- 艺术：构图平衡有焦点、色彩和谐、字体层级清晰、视觉冲击强
- 商业：符合品牌规范、契合目标受众、多尺寸适配

## 调用方式

由 `art-design-unified-workflow` 在各阶段调用：需求分析（plan_analysis）→ 策略（plan_strategy）→ 技术（plan_tech）→ 色彩（color_psychology）→ 评估（evaluate）。每个阶段只查询该阶段 step 对应的少量条目。

## 注意事项

1. 知识库为只读快照（无自学习管道）；条目含 quality_score 与 evidence，优先采用高分条目并保留来源
2. 单次查询 LIMIT ≤ 5；content JSON 取回后再解析
3. 知识可能过时（快照日期见 created_at），涉及外部事实时先核实再使用
