# Ad Design Style Reference

## User feedback pattern: "Too photo-realistic, not artistic enough"

### What went wrong in first attempt
- Used写实风格 (realistic) without style clarification
- Generated photo-like image with insufficient edge transition
- Transition zone not explicitly specified in prompt
- User said: "过渡不自然，交界处没有jie'bian渐变，生成的图像t'ya太像照片，没有艺术化处理"

### Corrective approach
1. **Ask about style first** — don't assume photo-realistic
2. **Propose style options** — give user choice between artistic approaches
3. **Explicit edge transition specs** — specify 150–200px width, technique
4. **Add "非照片写实"** — anti-photorealistic constraint in prompt

## Style comparison (user session example)

| 风格 | 特点 | 适合场景 | 上海题材应用 | 优点 | 缺点 |
|------|------|----------|-------------|------|------|
| 油画 | 厚重笔触、丰富色彩层次 | 文化宣传、高端品牌 | 黄浦江夜景，石库门质感 | 艺术价值高 | 制作难度大 |
| 水彩 | 透明质感、清新淡雅 | 旅游宣传、文艺活动 | 外滩建筑群，朦胧梦幻 | 轻盈灵动 | 冲击力弱 |
| 插画 | 手绘感强、自由度高 | 年轻受众、创意品牌 | 卡通化陆家嘴和石库门 | 记忆点强 | 可能不够正式 |
| 国画 | 水墨韵味、留白意境 | 文化传承、传统节日 | 水墨山水+天际线 | 文化认同强 | 受众面窄 |
| **新中式插画** | **工笔+扁平色块** | **传统现代融合** | **线条勾勒石库门，色块表现陆家嘴** | **文化深度+现代感** | **需设计功底** |
| 几何简约 | 色块拼接、极简主义 | 现代品牌、科技 | 几何构成陆家嘴剪影 | 现代感强 | 可能缺乏情感 |
| 霓虹发光 | 荧光色彩、光晕效果 | 娱乐场所、夜间活动 | 陆家嘴夜景霓虹 | 冲击极强 | 可能浮夸 |
| 3D渲染 | 立体空间、真实光影 | 科技产品、建筑展示 | 3D模型表现空间关系 | 震撼力强 | 成本高 |
| 赛博朋克 | 霓虹+暗调、未来感 | 科技主题、年轻文化 | 未来上海，霓虹灯光 | 前沿感强 | 小众审美 |
| 故障艺术 | 像素化、色彩分离 | 叛逆文化、创意广告 | 数字故障感城市 | 先锋感强 | 理解门槛高 |

## Style recommendations for "传统与现代交融" theme

### 1. 新中式插画风格 (★★★★★ recommended)

**Why highest**:
- Cultural depth: 工笔线条 + 扁平化色块
- Visual harmony: 水墨过渡自然
- Judge acceptance: Both traditional and modern elements balanced
- Matches course grading criteria

**Technique**:
- Traditional elements: 工笔线条勾勒石库门，细腻优雅
- Modern elements: 扁平化色块表现陆家嘴，简洁明快
- Colors: 墨黑, 朱砂红, 石青, 浅灰
- Layout: 留白布局, 东方美学

### 2. 半抽象油画风格 (★★★★)

**Why strong**:
- High artistic value
- Rich color expression for urban lighting
- Between figurative and abstract = design intentionality

**Technique**:
- 厚笔触油画质感
- 不过度写实，介于具象与抽象之间
- 黄昏色调，油画质感

**Risk**: Higher technical difficulty

### 3. 几何水墨融合 (★★★★)

**Why strong**:
- Extremely innovative
- Elegant tone
- Strong design statement

**Technique**:
- 水墨晕染背景
- 几何色块主体
- 黑白+点缀色

**Risk**: Requires strong design skills

## Edge transition techniques that worked

### Problem: Vague "自然过渡"指令 insufficient

First attempt: "过渡区：从现代渐变到传统，色调自然融合，无生硬分割"
Result: User said "交界处没有jie'bian渐变"

### Solution: Explicit specification

**Pattern that worked**:
```
过渡处理：沿对角线中部设置"边缘渐变"过渡带（约150–200像素），
从冷调向暖调自然平滑过渡，避免生硬分割线。
可用半透明色带、光晕或纹理叠加以实现边缘渐变。
```

**Key elements**:
- Transition zone width: 150–200像素 (explicit)
- Technique: "边缘渐变", "半透明色带", "光晕", "纹理叠加"
- Direction: "从{冷调}向{暖调}" (明确色彩方向)
- Negative constraint: "避免生硬分割线"

## Print specification checklist

- A4 format: 2480 × 3508 pixels at 200 dpi
- Output formats: PNG/JPG for submission + layered source (PSD/AI)
- Sufficient negative space for text overlay (upper 1/3 typically)
- Resolution minimum: 200 dpi (course requirement)

## Prompt engineering template for posters

```
{Style}，{Subject}海报。
构图：{Composition description}，{Key elements with style}。

{Area A}：{Description}，{Style/texture details}。
{Area B}：{Description}，{Style/texture details}。

过渡处理：{Transition type}，{Color zones}，{Gradation width ~150-200px}，{Natural/soft}。

色彩：{Color palette}。
整体：{Mood/atmosphere}，{Layout approach}。
尺寸：2480x3508像素，200dpi，A4竖版比例。
```

## User preference (from this session)

For advertising/poster work: **Prefer artistic styles** (illustration, painting, geometric) over photo-realistic.

Photo-realistic often feels "too literal" and lacks design intentionality for poster/advertising contexts. User explicitly corrected: "生成的图像t'ya太像照片，没有艺术化处理"

When style not specified, **ask first** rather than assuming realistic default.