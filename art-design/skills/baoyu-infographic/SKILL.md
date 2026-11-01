---
name: baoyu-infographic
description: "Infographics: 21 layouts x 21 styles (信息图, 可视化)."
---

# Infographic Generator

Adapted from [baoyu-infographic](https://github.com/JimLiu/baoyu-skills) for CodeBuddy Code's tool ecosystem.

两个维度：**layout**（信息结构）× **style**（视觉美学），自由组合。

## When to Use

用户要求信息图、视觉摘要、"信息图"、"可视化"、"高密度信息大图"时触发。提供内容（文本/路径/URL/主题），可选 layout、style、aspect、语言。

> 前置：属于图像创作，先遵循 `art-design-unified-workflow` Phase 1 澄清铁律。

## Options

| Option | Values |
|--------|--------|
| Layout | 21 种（Layout Gallery），默认 bento-grid |
| Style | 21 种（Style Gallery），默认 craft-handmade |
| Aspect | landscape(16:9) / portrait(9:16) / square(1:1) / 自定义 W:H |
| Language | zh / en / ja… |

## Layout Gallery（`references/layouts/<layout>.md`）

`linear-progression`(时间线/流程) `binary-comparison` `comparison-matrix` `hierarchical-layers` `tree-branching` `hub-spoke` `structural-breakdown` `bento-grid`(默认) `iceberg` `bridge` `funnel` `isometric-map` `dashboard` `periodic-table` `comic-strip` `story-mountain` `jigsaw` `venn-diagram` `winding-roadmap` `circular-flow` `dense-modules`(高密度数据)

## Style Gallery（`references/styles/<style>.md`）

`craft-handmade`(默认) `claymation` `kawaii` `storybook-watercolor` `chalkboard` `cyberpunk-neon` `bold-graphic` `aged-academia` `corporate-memphis` `technical-schematic` `origami` `pixel-art` `ui-wireframe` `subway-map` `ikea-manual` `knolling` `lego-brick` `pop-laboratory` `morandi-journal` `retro-pop-grid` `hand-drawn-edu`

## Recommended Combinations

Timeline→`linear-progression+craft-handmade` · Steps→`linear-progression+ikea-manual` · A vs B→`binary-comparison+corporate-memphis` · Hierarchy→`hierarchical-layers+craft-handmade` · Venn→`venn-diagram+craft-handmade` · Funnel→`funnel+corporate-memphis` · Cycles→`circular-flow+craft-handmade` · Technical→`structural-breakdown+technical-schematic` · Metrics→`dashboard+corporate-memphis` · Educational→`bento-grid+chalkboard` · Journey→`winding-roadmap+storybook-watercolor` · Categories→`periodic-table+bold-graphic` · Product Guide→`dense-modules+morandi-journal` · Technical Guide→`dense-modules+pop-laboratory` · Trendy Guide→`dense-modules+retro-pop-grid` · Edu Diagram→`hub-spoke+hand-drawn-edu` · Process Tutorial→`linear-progression+hand-drawn-edu`

## Keyword Shortcuts

| 关键词 | Layout | 推荐 Style | 默认 Aspect | Notes |
|--------|--------|-----------|------------|-------|
| 高密度信息大图 | `dense-modules` | morandi-journal / pop-laboratory / retro-pop-grid | portrait | — |
| 信息图 | `bento-grid` | craft-handmade | landscape | 极简：干净画布、留白、无复杂纹理背景 |

## Output Structure

`~/.codebuddy/projects/Users-<username>/creative/art/infographic-{topic-slug}/`：`source-{slug}.{ext}`、`analysis.md`、`structured-content.md`、`prompts/infographic.md`、`infographic.png`。冲突加时间戳。

## Core Principles

- 源数据忠实保留，不概括不改写（"73% 增长"保持原样）
- 先定学习目标再结构化
- 面向视觉传达组织（标题/标签/视觉元素）
- **剥离凭据**——源内容中的 key/token 不进输出

## Workflow

1. **分析** → `analysis.md`（读 `references/analysis-framework.md`；已存在则备份改名）
2. **结构化内容** → `structured-content.md`（读 `references/structured-content-template.md`；标题/目标/分区/数据原样复制）
3. **推荐组合**：先查关键词捷径，否则按数据结构/语调/受众给 3-5 个组合
4. **AskUserQuestion 确认**：Q1 组合（≥3 个带理由）→ Q2 aspect → Q3 语言（仅源语言≠用户语言时）
5. **组装 prompt** → `prompts/infographic.md`：layout 定义 + style 定义 + `references/base-prompt.md` + 结构化内容 + 确认语言；`{{ASPECT_RATIO}}` 用比例字符串
> 生图后端主路线见 `art-design-unified-workflow`（ComfyUI :1238 客户端脚本做 txt2img；ImageGen 为备选/积分制）。下面 ImageGen 用法同样适用于 ComfyUI 客户端（--prompt-file 传 prompt 文本）。

6. **生成（ImageGen）**：aspect 映射 landscape→`1536x1024`、portrait→`1024x1536`、square→`1024x1024`，自定义比例取最近；`output_dir` 绝对路径；失败重试一次；**积分每张 5–10，生成前告知**
7. **报告**：topic、layout、style、aspect、语言、输出路径、文件清单

## 文字密度对策（CodeBuddy 重要适配）

信息图文字多，扩散模型（尤其中文）**准确率近零**。按文字密度选路线：

| 文字密度 | 路线 |
|---|---|
| 低（≤5 短标签，英文/数字） | ImageGen 直接生成，prompt 明确 LABELS，允许 1-2 轮迭代 |
| 高（中文为主/长句/数据表） | **确定性路线**：ImageGen 生成无文字底图（prompt 写 "no text, blank label areas, avoid any letters"）→ PIL 按 structured-content 精确排版文字 → `compositor composite`/GIMP 合成；或纯 PIL/HTML 渲染整图 |
| 混合 | 底图 + PIL 只补标题/关键数字 |

PIL 排版见 `artistic-text-generation`；评估用 `art-design-visual-qa`（重点查文字可读性与数据正确性）。

## Pitfalls

1. 数据完整性第一，禁止改写统计数字
2. 剥离凭据
3. 每个分区一个概念，超载即不可读
4. style 全图一致，不混风格
5. ImageGen 尺寸有限，取最近比例
6. 高密度中文信息图必走确定性路线，不要指望扩散模型写字
