---
name: art-design-unified-workflow
description: Use when the user asks for ANY image creation, editing, or art/design work — 生图/出图/画一张/做一张图/插画/海报/壁纸/头像/封面/贴纸/logo/名片/VI/banner/表情包/绘本/儿童插画/漫画/信息图/UI界面/mockup/临摹/风格迁移/换风格/修图/换背景/局部重绘/inpaint/img2img/txt2img/AI出图. MUST load before calling ImageGen or any image generation tool. NEVER skip Phase 1 clarify + Phase 2 planning even if a prompt or reference is already at hand. Coordinates all art-design sub-skills (prompt-engineering, visual-qa, gimp-processing, layered-psd-cli, domain-knowledge, brand-collateral, semantic-stylization, artistic-text, baoyu-*, pixel-art, creative-ideation) and the compositor CLI.
---

# Art Design Unified Workflow (艺术设计统一生图流程)

本框架移植自 Hermes agent 的 art-design skill 体系，已适配 CodeBuddy Code + 本机 compositor CLI。

## Overview

这是艺术设计/生图任务的**统一入口技能**。负责：

1. **任务类型识别**：海报/插画/品牌设计/VI 手册/UI-UX 界面/信息图/风格迁移/局部编辑
2. **子技能协调**：按需调用专门子技能，避免重复执行
3. **阶段管理**：需求→策划→执行→评估→迭代的完整流程
4. **质量保证**：三维评估框架（见 `art-design-visual-qa`）
5. **知识驱动**：所有领域知识经 `art-design-domain-knowledge` 从本地知识库查询（`~/.codebuddy/assets/art-design/knowledge.db`，8876 条）

## ⚠️ 铁律：禁止跳流程

**绝对禁止直接调用生图工具（ImageGen 等）跳过 Phase 1-2。** 任何图像创作任务必须先完成需求澄清和策划确认。违反后果：需求不明确、文件散落、无版本管理。

**延伸规则：即使会话内已有 prompt 或策划方案，也不得跳过 Phase 1-2。**
- 上一轮遗留的 `prompts/prompt_v1.md` 先加载确认是否仍有效，而不是直接生成
- 用户说"重新生成"：先读既有 prompt 确认需求变化，再进 Phase 4
- 例外：用户明确说"用上次的方案，别再问我"或 "just do it"，可直接进 Phase 4

## 生图后端分工（本机环境）

| 需求 | 后端 | 说明 |
|------|------|------|
| 文生图 (txt2img) | **ComfyUI :1238**（主路线，已确认） | 客户端脚本见下方"ComfyUI 生图服务规则"；内置 ImageGen 曾 401，可用时亦可 |
| 文生图备选 | **ImageGen 工具**（CodeBuddy 内置） | prompt + size + quality。**每张约 5–10 积分，生成前必须告知用户** |
| 图生图 (img2img) | **ImageGen 工具** | `image1` 传参考图路径；`input_fidelity` 控制贴近程度；多参考图用 image2/image3（ComfyUI 客户端暂只支持 txt2img） |
| 抠图/换背景 | `compositor extract` | CLI 见下方工具分工表 |
| 局部重绘/inpaint | `compositor inpaint` | mask 可由 YOLO bbox 或手工生成 |
| 换脸 | `compositor face-swap` | insightface 模型已就绪 |
| 图层合成/羽化融合 | `compositor composite` | 前景+背景精确合成 |
| 多步流水线 | `compositor pipeline` | JSON 配置串联 |
| 结构校验 | `compositor face-detect` / `pose-estimate` | 人脸/姿态客观检测 |
| 分层 PSD 交付 | GIMP 2.10 批处理 | 见 `gimp-layered-psd-cli` |
| 复杂艺术字 | GIMP 批处理 | 见 `artistic-text-generation` |

**compositor CLI 路径**：`$COMPOSITOR_BIN`（默认 `~/.codebuddy/bin/compositor`，即 install.sh 编译后软链的位置；可用环境变量覆盖；缺失则由 install.sh 执行 `swift build` 并软链）。

## ComfyUI 生图服务规则

入口地址由 `setup.sh` 写入 `~/.codebuddy/assets/art-design/local_config.json` 的 `comfyui_base`（各机自定的 ComfyUI 服务，例如某台 ECS 上的 nginx→ComfyUI 反代）。**本框架不在任何文件里硬编码该 URL**，客户端脚本 `comfyui_generate.py` 运行时从 `local_config.json` 读取。客户端：

```bash
~/.venv-art/bin/python ~/.codebuddy/assets/art-design/comfyui_generate.py \
  --prompt-file prompts/prompt_vN.txt --out candidates/base.png \
  --workflow zimage|qwen|flux [--w 1024 --h 1536 --steps N --guid X --seed -1]
```

工作流选择：`zimage`（z-image-turbo，4步/cfg2.5，~1-1.5min，快草稿）；`qwen`（Qwen-Image distill，8步/cfg1.0，油画肌理等艺术质感明显更佳，实测 1024x1024 约 2.5min，大图预留 6.5min）；`flux`（flux1-dev，20步）。脚本自动把 `avoid:` 行拆成 negative。

**硬性约束（都踩过坑，必须遵守）**：
1. **串行调用，禁止并发**——单 GPU 与同机 LLM 共享显存池；脚本内置 flock，本地并发会被直接拒绝；agent 侧一次只挂一个任务
2. 提交前脚本自动 `POST /free`（卸载模型防 OOM）；整体预算按 10 分钟设计，轮询 /history 而非同步等 /prompt
3. 任务失败不体现在 /prompt 响应，要看 /history/{pid} 的 `status.status_str=="error"`（脚本已处理并打印 execution_error）
4. 密钥只在 `local_config.json` 指向的 key 文件（默认 `~/.codebuddy/assets/art-design/comfyui_1238.key`，600 权限）；**禁止把 key 写入代码、日志、提交物**；该生图服务为公网端口，泄露即失控
5. 图片落在服务器 `~/ComfyUI/output/`（磁盘 72%），任务收尾时提醒用户清理服务器端文件
6. `--seed` 固定可复现；-1 随机。meta JSON 随图保存
7. 模型名必须与服务器一字不差（`GET /object_info/UNETLoader` 核对）；UNETLoader 必填 weight_dtype

## 本地工具环境

- 知识库：`~/.codebuddy/assets/art-design/knowledge.db`（只读，查询模板见 `art-design-domain-knowledge`）
- 对象检测：`~/.venv-art/bin/python ~/.codebuddy/skills/semantic-gimp-artistic-stylization/scripts/object_detection.py <image> [conf] [json|text]`
- 视觉评估：`~/.codebuddy/skills/art-design-visual-qa/scripts/visual_quality_assessor.py`（llama.cpp 多模态）或 CodeBuddy 原生 ViewImage
- GIMP：`/Applications/GIMP.app/Contents/MacOS/gimp-console -i --batch-interpreter=python-fu-eval -b '<python2代码>' -b '(gimp-quit 0)'`（**Python 2.7 / gimpfu API**，见 gimp 技能注意事项）

## 输出目录约定（所有生图任务的统一根目录）

每个任务在 `~/.codebuddy/projects/Users-<username>/creative/art/<task_name>/` 下建独立目录。`<task_name>` 为简短描述性名称（如 `端午插画`、`VI名片`、`风格迁移`）。

```
~/.codebuddy/projects/Users-<username>/creative/art/<task_name>/
├── final/          # 最终交付：JPG / PNG / PSD（仅最终版本）
├── candidates/     # 通过评估但未定稿的版本
├── prompts/        # 提示词版本记录 + 变更日志
├── source_layers/  # 分层 PNG / PSD 脚本
├── analysis/       # 评估报告、区域分析、对比图、YOLO 检测结果
└── temp/           # 中间产物、调试输出、未定稿
```

规则：中间/调试产物进 `temp/`；过评估进 `candidates/`；定稿进 `final/`；提示词按版本存 `prompts/`；评估报告进 `analysis/`。**禁止把产物散落到 /tmp、桌面根目录**。

## 统一工作流程

### Phase 1: 任务识别与需求澄清
```
输入: 用户自然语言请求
输出: 任务类型 + 明确需求 + 任务目录
步骤:
1. 识别任务类型（海报/插画/品牌/VI/UI-UX/信息图/风格迁移/局部编辑）
2. 澄清不可推断信息（用途/尺寸/质量要求/目标平台）→ 使用 AskUserQuestion 工具
3. 给出可推断建议（构图/色彩/风格）作为选项
4. 创建任务目录 ~/.codebuddy/projects/Users-<username>/creative/art/<task_name>/
```
**澄清格式（必须遵守）**：用 AskUserQuestion，每个分类 3–4 个可选项 + 描述，选项含风格推荐；绝不问开放式问题；用户选定即进 Phase 2。

**调用**：`art-design-domain-knowledge`（任务类型特征查询）

### Phase 2: 策划与需求确认
```
输入: 任务类型 + 明确需求
输出: 策划方案 + 提示词初版（存 prompts/prompt_v1.md）
步骤:
1. 需求分析 → knowledge.db 查询 domain=<任务域> step=plan_analysis
2. 创作策略 → step=plan_strategy（含色彩理论）
3. 技术路线 → step=plan_tech
4. 保存 prompts/prompt_v1.md
```
**调用**：`art-design-domain-knowledge`、`art-design-prompt-engineering`

### Phase 3: 原图分析（有原图时）
```
输入: 原图路径
输出: 原图特征总结 + 视觉传达重点 + analysis/report.md
步骤:
1. 多模态语义分析（ViewImage 或 visual_quality_assessor.py）
2. YOLO 对象检测（object_detection.py → analysis/detections.json）
3. PIL 统计（尺寸/色彩分布/对比度）
```
**调用**：`art-design-visual-qa`

### Phase 4: 素材生成
```
前置铁律：局部编辑/重绘/替换任务必须先完成对象识别——Phase 3 中明确目标对象，生成精确 mask/bbox 并验证质量。未识别直接 inpaint = 盲操作，禁止。
步骤:
1. 背景层（ImageGen img2img 低强度：高 input_fidelity）
2. 主体层（img2img 中/高强度：中低 input_fidelity）
3. 附属元素（txt2img 或 img2img）
4. 未过评估 → candidates/；调试输出 → temp/
```
**调用**：`art-design-prompt-engineering`（构建 9 维提示词）、ImageGen、compositor CLI
**积分规则**：每批生成前告知预计张数与积分消耗。

### Phase 5: 素材加工
```
步骤: 目标尺寸画布 → 按序导入元素 → 位置/比例 → 混合模式/透明度 → 统一色调
合成用 compositor composite / PIL；图层交付用 GIMP（gimp-layered-psd-cli）
中间产物 → temp/；过评估 → candidates/
```
**调用**：`art-design-gimp-processing`、`artistic-text-generation`（如需装饰文字）

### Phase 6: 质量评估
```
步骤:
1. Vision Analysis（多模态评估）
2. PIL/compositor 量化指标（face-detect/pose-estimate 验证主体结构）
3. 综合评分：客观技术 20–30% + 主观艺术 70–80%
4. 评估报告 → analysis/
```
**调用**：`art-design-visual-qa`

### Phase 7: 自修正与迭代
```
步骤: 负面特征→negative、正面特征→positive 修正提示词 → 存 prompts/prompt_vN.md → 重新生成 → 循环直到达标 → 最终版复制 final/
每轮只修复最大缺陷（见 prompt-engineering 迭代规则）。
```

## 专用工作流选择

| 任务类型 | 走专用技能 |
|---|---|
| VI 手册/品牌 mockups/多尺寸广告 | `visual-brand-collateral-design`（PIL 合成 + 官方 LOGO 资产，禁 AI 生成 LOGO；输出 MANIFEST.json + 分层 PSD） |
| 照片转插画/油画/临摹（保结构） | `semantic-gimp-artistic-stylization`（YOLO 分区保护 + GIMP 分区域处理，非全局滤镜） |
| 装饰/艺术字 | `artistic-text-generation`（**中文文字禁用扩散模型**，准确率≈0；PIL/GIMP 处理） |
| 儿童绘本/文章配图 | `baoyu-article-illustrator` |
| 知识漫画 | `baoyu-comic` |
| 信息图/数据可视化 | `baoyu-infographic`（查 `art-design-domain-knowledge` 的 charts-reference.md 选图表类型与配色） |
| 照片→像素画 | `pixel-art`（PIL 脚本） |
| UI/UX 界面 | 见下节 |

## UI/UX 界面设计（独立于扩散模型的工作流）

适用：网站/APP/Dashboard/Landing Page/设计系统。
```
Phase 1 需求澄清（平台/用户/功能/风格倾向）
Phase 2 策略：查 art-design-domain-knowledge 的 ui-reasoning-reference.md（产品类型→模式）、
  ui-ux-styles-reference.md（1-3 种风格）、ui-ux-color-reference.md（配色）、
  ui-ux-typography-reference.md（字体）、motion-patterns-reference.md（动效，可选）
Phase 3 Mockup：布局用 PIL/GIMP 合成（不用扩散模型生成具体界面内容；装饰性配图可用 ImageGen）
Phase 4 评估：一致性/层级/对比度/可访问性（设计原则，不依赖扩散）
Phase 5 迭代
```
核心差异：生成靠"布局模式 + 合成"而非扩散模型；输出可导出 HTML/CSS；评估重可用性。

## 避免重复的关键设计

1. 单一职责：子技能只管一个功能域，主技能协调；子技能间不相互调用
2. 数据流标准化：需求/策划/素材/评估统一结构，避免重复传递
3. 阶段门控：主技能控制阶段进入时机
4. 知识库统一：一切领域知识经 `art-design-domain-knowledge` → knowledge.db
5. 评估统一：唯一评估入口 `art-design-visual-qa`

## 知识库 7 步渐进披露

knowledge.db 按流程步骤组织知识（domain × step × depth）：
`clarify → plan_analysis → plan_strategy → plan_tech → execute_generate → execute_process → evaluate`（img2img 识别类另有 `recognize` 步骤）。
**每个 Phase 只查询当前步骤所需记录**（overview→detail→advanced 渐进），不要一次拉全部。查询模板见 `art-design-domain-knowledge`。

## 验证清单（任务完成前自查）

- [ ] Phase 1 澄清已用 AskUserQuestion 完成（或用户 explicitly 说"别问了"）
- [ ] prompts/prompt_v1.md 已保存
- [ ] 局部编辑任务：对象识别 + mask 已验证
- [ ] 评估报告在 analysis/，最终版在 final/
- [ ] 生成积分消耗已告知用户
