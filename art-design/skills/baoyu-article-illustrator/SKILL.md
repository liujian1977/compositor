---
name: baoyu-article-illustrator
description: "Article illustrations: type × style × palette consistency. 为文章配图，生成风格统一的插图。"
---

# Article Illustrator

 Adapted from [baoyu-article-illustrator](https://github.com/JimLiu/baoyu-skills) for CodeBuddy Code's tool ecosystem.

分析文章，确定配图位置，按 **Type × Style × Palette** 一致性生成插图。

## When to Use

用户要求"为文章配图"、"illustrate article"、"add images"时触发。提供文章（路径或粘贴内容），可选指定 type、style、palette、density。

> 前置：本任务属于图像创作，先遵循 `art-design-unified-workflow` 的 Phase 1 澄清铁律（除非用户明确"别再问"）。

## Three Dimensions

| Dimension | Controls | Examples |
|-----------|----------|----------|
| **Type** | Information structure | infographic, scene, flowchart, comparison, framework, timeline |
| **Style** | Rendering approach | notion, warm, minimal, blueprint, watercolor, elegant |
| **Palette** | Color scheme (optional) | macaron, warm, neon — overrides style's default colors |

组合自由：`type=infographic, style=vector-illustration, palette=macaron`。或用预设（`references/style-presets.md`）。

## Types

| Type | Best For |
|------|----------|
| `infographic` | Data, metrics, technical |
| `scene` | Narratives, emotional |
| `flowchart` | Processes, workflows |
| `comparison` | Side-by-side, options |
| `framework` | Models, architecture |
| `timeline` | History, evolution |

风格库：`references/styles.md`（含 Type × Style 兼容性）。

## Output Structure

```
{output-dir}/
├── source-{slug}.{ext}    # 仅粘贴内容时
├── outline.md
├── prompts/
│   └── NN-{type}-{slug}.md
└── NN-{type}-{slug}.png
```

**默认输出目录**：

| 输入 | 输出目录 | Markdown 插入路径 |
|-------|------------------|----------------------|
| 文章文件路径 | `{article-dir}/imgs/` | `imgs/NN-{type}-{slug}.png` |
| 粘贴内容 | `~/.codebuddy/projects/Users-<username>/creative/art/<topic-slug>/` | 相对路径 |

用户指定别的布局则遵从。**Slug**: 2-4 词 kebab-case。**冲突**: 追加 `-YYYYMMDD-HHMMSS`。

## Core Principles

- **可视化概念而非比喻**——文章用比喻（"电锯切西瓜"）时画底层概念
- **标签用文章真实数据**——实际数字、术语、引文，不用泛化占位符
- **Prompt 文件是可复现记录**——每张图生成前必须有 `prompts/` 下的 prompt 文件
- **剥离密钥**——写盘前扫描源内容中的 API key/token/凭据并剔除

## Workflow

```
- [ ] Step 1: 检测参考图（如有）
- [ ] Step 2: 分析内容
- [ ] Step 3: 确认设置（AskUserQuestion，一次最多 2-3 问）
- [ ] Step 4: 生成 outline
- [ ] Step 5: 生成 prompts
- [ ] Step 6: 生成图片（ImageGen）
- [ ] Step 7: 收尾插入
```

### Step 1: 参考图

用户提供参考图时：用 `ViewImage`（自包含 query：描述风格/配色/构图/主体）提取文字描述，记入 `{output-dir}/references/NN-ref-{slug}.md`。ImageGen 的 img2img（`image1`=参考路径 + 合适 `input_fidelity`）可直接用参考图，同时保留文字描述进 prompt。

### Step 2: 分析

内容类型（Technical/Tutorial/Methodology/Narrative）、用途（information/visualization/imagination）、2-5 个论点、插图位置。写入 `{output-dir}/analysis.md`。

### Step 3: 确认设置（AskUserQuestion）

跳过用户已给出的项。顺序：Q1 预设或类型 → Q2 密度（minimal 1-2 / balanced 3-5 / per-section / rich 6+）→ Q3 风格（选了预设可跳）→ Q4 配色（可选）→ Q5 语言（仅在文章语言不明时）。

### Step 4: Outline → `outline.md`

frontmatter（type, density, style, palette, image_count）+ 每条插图：Position / Purpose / Visual Content / Filename。

### Step 5: Prompts（BLOCKING）

每张图必须按 `references/prompt-construction.md` 建 prompt 文件存 `prompts/NN-{type}-{slug}.md`（YAML frontmatter）。Prompt 必须含结构化段落（ZONES / LABELS / COLORS / STYLE / SIZE）；LABELS 用文章真实数据。**注意**：ImageGen 无独立 negative prompt——把禁止项写成 prompt 尾部 `avoid: ...`。

> 生图后端主路线见 `art-design-unified-workflow`（ComfyUI :1238 客户端脚本做 txt2img；ImageGen 为备选/积分制）。

### Step 6: 生成图片（ImageGen）

1. 读 prompt 文件 → 调 `ImageGen(prompt=..., size=..., quality=...)`，`output_dir` 指向输出目录
2. Aspect 映射：16:9/4:3 → `size=1536x1024`；9:16/3:4 → `1024x1536`；1:1 → `1024x1024`
3. **积分规则：每张约 5–10 积分，批量生成前告知张数与预计消耗**
4. 失败自动重试一次

### Step 7: 收尾

对应段落后插入 `![描述](相对路径/NN-{type}-{slug}.png)`，alt 文本用文章语言。报告：文章、type、density、style、palette、X/N 成功。

## Modification

| Action | Steps |
|--------|-------|
| Edit | 先改 prompt → 重生成 → 更新引用 |
| Add | 位置 → prompt → 生成 → 更新 outline → 插入 |
| Delete | 删文件 → 删引用 → 更新 outline |

## References

| File | Content |
|------|---------|
| `references/workflow.md` | 详细流程 |
| `references/usage.md` | 调用示例 |
| `references/styles.md` + `references/styles/` | 风格库 + 配色库 |
| `references/style-presets.md` | 预设捷径 |
| `references/prompt-construction.md` | Prompt 模板 |

## Pitfalls

1. **数据完整性第一**——"73% increase" 不能变成"大幅增长"
2. **剥离密钥**——源内容中的凭据不得进入任何输出文件
3. **不literal画比喻**——画底层概念
4. **prompt 文件必须先行**——没有存档 prompt 不得生成
5. **ImageGen 尺寸映射**——只支持有限尺寸，取最接近的
6. **中文文字不靠扩散模型**——插图中的中文标签用 PIL 艺术字后期合成（见 artistic-text-generation），或 prompt 里明确要求极少文字并接受重生成迭代
