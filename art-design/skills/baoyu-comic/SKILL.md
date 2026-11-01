---
name: baoyu-comic
description: "Knowledge comics (知识漫画): educational, biography, tutorial. 教育漫画/人物传记/教程漫画。"
---

# Knowledge Comic Creator

Adapted from [baoyu-comic](https://github.com/JimLiu/baoyu-skills) for CodeBuddy Code's tool ecosystem.

生成原创知识漫画，art style × tone 自由组合。

## When to Use

用户要求知识/教育/传记/教程漫画或"知识漫画"、"Logicomix-style"时触发。提供内容（文本/路径/URL/主题），可选 art style、tone、layout、aspect、语言。

> 前置：属于图像创作，先遵循 `art-design-unified-workflow` Phase 1 澄清铁律。

## Reference Images

CodeBuddy 的 ImageGen 支持 img2img（`image1..3` + `input_fidelity`）。参考图用法：

- 文件路径 → 复制到输出目录 `refs/NN-ref-{slug}.{ext}` 存证
- **style/palette 提取**：用 `ViewImage` 提取风格/配色特征文本，写进每页 prompt 正文（保证跨页一致）
- **direct 用法**：该页用 ImageGen img2img 传参考图 + 高 `input_fidelity`
- 角色一致性靠 `characters/characters.md` 里的**文字描述**内嵌进每页 prompt（角色设定页 PNG 只是人审产物，不作为模型输入）

frontmatter 记录：
```yaml
references:
  - ref_id: 01
    filename: 01-ref-scene.png
    usage: style
    traits: "muted earth tones, soft-edged ink wash, low-contrast backgrounds"
```

## Options

| Option | Values |
|--------|--------|
| Art | ligne-claire (default), manga, realistic, ink-brush, chalk, minimalist — `references/art-styles/<style>.md` |
| Tone | neutral (default), warm, dramatic, romantic, energetic, vintage, action — `references/tones/<tone>.md` |
| Layout | standard, cinematic, dense, splash, mixed, webtoon, four-panel — `references/layouts/` |
| Aspect | 3:4 (default), 4:3, 16:9 |
| Language | auto（用户输入语言优先） |

Presets（有额外规则，选中后读 `references/presets/<preset>.md`）：`ohmsha`(manga+neutral, 视觉隐喻)、`wuxia`(ink-brush+action)、`shoujo`、`concept-story`、`four-panel`(起承转合)。兼容性矩阵与内容信号→预设表：`references/auto-selection.md`。

## File Structure

输出目录 `~/.codebuddy/projects/Users-<username>/creative/art/comic-{topic-slug}/`（slug 2-4 词 kebab-case，冲突加时间戳）：

| File | Description |
|------|-------------|
| `source-{slug}.md` | 源内容存档 |
| `analysis.md` / `storyboard.md` | 分析 / 分镜 |
| `characters/characters.md` (+ .png 审查产物) | 角色定义 |
| `prompts/NN-{cover|page}-[slug].md` | 生成 prompt（复现记录） |
| `NN-{cover|page}-[slug].png` | 生成图 |
| `refs/NN-ref-{slug}.{ext}` | 用户参考图（可选） |

## Workflow

```
- [ ] Step 1: Setup & Analyze（analysis.md；检查既有目录冲突）
- [ ] Step 2: 确认风格+选项 ⚠️ REQUIRED（AskUserQuestion）
- [ ] Step 3: storyboard + characters
- [ ] Step 4: 审 outline（仅用户要求时）
- [ ] Step 5: prompts
- [ ] Step 6: 审 prompts（仅用户要求时）
- [ ] Step 7: 生成图（7.1 角色设定页(如需) → 7.2 各页）
- [ ] Step 8: 完成报告
```

**AskUserQuestion 超时处理**：视为该题默认值，继续问剩余题；** visibly 报告默认值**（"Style: 默认 ohmsha（未响应），要改随时说"），不要把一次超时当成全部默认。

> 生图后端主路线见 `art-design-unified-workflow`（ComfyUI :1238 客户端脚本做 txt2img；ImageGen 为备选/积分制）。

### Step 7: ImageGen

- **每页 prompt 必须先写入 `prompts/NN-{type}-[slug].md` 再生成**
- Aspect 映射：3:4/9:16/2:3 → `size=1024x1536`；4:3/16:9/3:2 → `1536x1024`；1:1 → `1024x1024`
- `output_dir` 用输出目录**绝对路径**；ImageGen 直接落盘本地文件（无需 curl）
- **积分：每张约 5–10 积分，多页漫画生成前告知总张数与消耗**
- 角色一致性：Step 5 里把 `characters/characters.md` 的文字描述内嵌每页 prompt
- 重生成：旧 prompt/png 先改名 `-backup-YYYYMMDD-HHMMSS`

## Partial Workflow

Storyboard only / Prompts only / Images only / Regenerate N（`references/partial-workflows.md`）。

## Page Modification

Edit：先改 prompt 文件 → 重生成。Add：新位置 prompt → 生成 → 重编号 → 更新 storyboard。Delete：删文件 → 重编号 → 更新 storyboard。

## References

`references/`：analysis-framework、character-template、storyboard-template、ohmsha-guide、base-prompt、workflow、auto-selection、partial-workflows、art-styles/、tones/、presets/、layouts/。

## Pitfalls

- 每页 10-30 秒，失败自动重试一次
- 敏感公众人物用风格化替代形象
- Step 2 确认不可跳过；Step 4/6 仅用户要求时
- **中文对白/拟声词**：扩散模型中文准确率近零——文字气泡留白，后期用 PIL 艺术字合成（artistic-text-generation），或 prompt 要求极少文字+接受迭代
- 剥离源内容中的凭据
