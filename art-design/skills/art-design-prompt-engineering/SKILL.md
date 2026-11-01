---
name: art-design-prompt-engineering
description: Use when generating art/design images with ImageGen (text-to-image) or image-to-image and the result needs controlled composition, style, iteration records, visual QA, and downstream GIMP/PSD editing rather than one-off prompt guessing. Part of art-design-unified-workflow Phase 2/4/7.
---

# Art/design prompt engineering

## Overview

用于 T2I/img2img 艺术设计生成。目标不是"好看的随机图"，而是**可控的候选图**：能通过视觉 QA、可用确定性编辑（compositor CLI / PIL / GIMP）完成终稿。配合 `art-design-unified-workflow` 使用。

生图后端：CodeBuddy **ImageGen 工具**（txt2img 用 prompt；img2img 用 image1 + input_fidelity）。尺寸用 `size` 参数（1024x1024 / 1536x1024 / 1024x1536）。无独立 negative prompt 参数——把禁止项写进 prompt 尾部（"avoid: ..."）或用于迭代修正描述。

## Prompt Structure

保持提示词结构化、可编辑（存 `prompts/prompt_vN.md`）：

```text
Subject/content:      主体内容
Composition/layout:   构图/布局锁定
Style/medium:         风格/媒介
Palette/lighting:     色彩/光照
Required details:     必须出现的细节
Forbidden drift:      禁止漂移项（写入 prompt 末尾 "avoid: ..."）
Technical output:     尺寸/格式/输出要求
```

中文任务用中文为主或双语，但关键视觉名词保留英文（模型对英文响应更稳）。

## Iteration Rule

每轮只修复最大缺陷：

1. 构图错 → 修构图锁定
2. 人体/脸/文字坏 → 局部修复（compositor inpaint / face-swap）或带细节优先级重生成
3. 色彩/明度错 → 调色板/明度子句
4. 风格太泛 → 调媒介/笔触/纹理
5. 候选好但不完美 → **转确定性后处理**（compositor composite / GIMP），不要无限重生成

## Prompt Log Template

```markdown
# Prompt Log

## Brief
- Assignment / Required format / Core visual goal / Accuracy constraints

## v1
Prompt:
Negative (avoid):
Result:
Failure:

## v2
Changed only:
Prompt:
Result:

## Final
Selected image:
Reason:
Post-editing needed:
```

## Scenario Recipes

### 书籍/儿童插画
- 主 prompt 锁定主体、情绪基调、页面格式、风格
- 避免生成大量可读文字
- 脸/手局部修复优先（inpaint）
- 终稿分层：背景/阴影/边框/主插画/细节修复/纸纹

### 海报/广告
- 主视觉与排版分离：主视觉用 ImageGen，标题/正文/二维码/版式用 PIL/GIMP/compositor composite 确定性添加
- 中文文字**绝不**用扩散模型生成
- 主视觉保持支配地位（40–60% 版面）

### 临摹 / copy-study
相似度重要时**不要**纯 T2I。用保结构确定性风格化（见 `semantic-gimp-artistic-stylization`）：
- resize/crop 参考图 → 保色彩/明度 → 提取轮廓层 → 加笔触/纸张/线条处理 → 文字简化为抽象标记

### VI / 品牌 mockup
**不 prompt 生成 logo**。官方资产 + 确定性合成（见 `visual-brand-collateral-design`）。扩散只用于背景氛围或非关键插画。

### img2img 强度控制（ImageGen input_fidelity）
- 保结构换风格（临摹/氛围）：`input_fidelity` 高
- 风格大改、构图保留：中
- 仅取灵感/色彩：低
- 局部改动优先 compositor inpaint，不要整图 img2img

## QA Checklist（交 art-design-visual-qa 执行前的自查）

- [ ] 图满足 brief 后才进入后处理
- [ ] 必需主体位置正确（可用 compositor pose-estimate/face-detect 客观验证）
- [ ] 手/脸/文字/logo 可接受
- [ ] 风格匹配任务而非"泛 AI 风"
- [ ] 有通往分层 PSD 的路径
- [ ] prompt log 精简

## Common Pitfalls

1. 超长 prompt 风格互相冲突
2. 让模型生成精确可读文字/logo
3. 无限重生成而非局部修复
4. 把"参考临摹"当自由 reinterpretation
5. 忘记最终交付物：JPG/PSD（/文档）
