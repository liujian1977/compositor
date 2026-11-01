# Kunshan Kunqu advertising coursework prompt bank

Use when a user needs a four-piece advertising-design coursework set and wants a theme that does **not** overlap with a separate Shanghai city-image final exam.

## Context

Coursework requirement pattern:
- Four formative advertising works around one theme:
  1. 报纸广告
  2. 杂志广告
  3. 招贴设计
  4. POP广告
- Submit editable/original production file + JPG.
- Avoid reusing a final-exam theme such as “魅力上海 · 城市印象”.

Recommended separate theme for a Suzhou/Kunshan student:
- Theme: `一曲昆山 · 水磨新声`
- Positioning: Kunqu opera intangible-cultural-heritage youth communication campaign
- Main slogan: `一曲昆山，唱响千年`
- Style: 新中式昆曲插画风 + 水墨渐变 + 现代几何版式
- Palette: 宣纸米白 `#F6F0E4`, 黛青 `#1F4E5F`, 胭脂红 `#B23A48`, 墨黑 `#1C1C1C`, 淡金 `#C8A45D`
- Core elements: 昆曲水袖, 江南园林窗棂, 折扇, 曲谱线条, 昆山水乡桥影, 宣纸纹理, 水墨晕染, 现代几何留白

Avoid final-exam overlap by excluding: 上海, 外滩, 陆家嘴, 东方明珠, 石库门, 黄浦江, 上海城市精神.

## Global image-generation guidance

For Chinese advertising deliverables, generate **text-free base visuals** first. Add all Chinese titles, body copy, dates, QR labels, and slogans later in Photoshop/Illustrator/Canva/PPT/PIL. Text-to-image models often corrupt Chinese typography; final coursework looks more professional when typography is composed manually.

Global negative prompt:
`非照片写实，不要真实摄影感，不要3D渲染，不要赛博朋克，不要欧美歌剧，不要京剧脸谱，不要上海城市元素，不要外滩，不要陆家嘴，不要东方明珠，不要石库门，不要黄浦江，不要错乱文字，不要乱码，不要水印，不要低清晰度。`

## 1. Newspaper ad / 报纸广告

Format target:
- 12cm × 18cm, vertical
- about 1417 × 2126 px at 300dpi
- Information-heavy, grid-based, high contrast, black/white or low-saturation four-color print.

Prompt:
```text
新中式昆曲插画风格，报纸广告竖版构图，主题为“昆山昆曲非遗文化推广”。画面左侧是一位昆曲演员的优雅水袖剪影，人物以工笔线条和少量胭脂红细节表现，右侧保留大面积干净留白用于后期排版文字信息。背景为宣纸米白色，带有轻微报纸纸张纹理和细腻网点印刷质感，下方融入昆山江南水乡小桥、园林窗棂、折扇和曲谱线条的淡墨轮廓。整体采用低饱和黑白灰为主，点缀黛青和胭脂红，版面规整，网格化布局，层级清晰，适合报纸广告阅读。艺术质感，非照片写实，传统工笔线条结合现代留白版式，画面中不要出现任何文字。

构图要求：左图右文，右侧约40%空间为空白文案区；上方留标题区域，下方留活动信息区域；主体清晰，边缘干净，高对比，适合报纸印刷。
尺寸：1417x2126像素，300dpi，竖版比例。
```

Suggested later typography:
- 主标题：一曲昆山，唱响千年
- 副标题：昆曲非遗文化推广计划
- 正文：从水磨腔到青春舞台，让昆曲走进当代生活

## 2. Magazine ad / 杂志广告

Format target:
- A4 spread landscape, 420mm × 297mm
- about 4961 × 3508 px at 300dpi
- High color fidelity, emotional/artistic visual, minimal text, generous whitespace.

Prompt:
```text
新中式昆曲插画风格，杂志跨页广告横版构图，主题为“昆曲的年轻化与东方美学”。画面中央偏左是一条流动的昆曲水袖，水袖像水墨云气和音乐旋律一样横向展开，从左侧胭脂红渐变到右侧黛青与月白色，形成优雅的视觉动线。背景为宣纸米白与淡墨水洗质感，隐约出现江南园林月洞门、昆山水乡桥影、折扇、曲谱线条和窗棂纹样。画面右侧保留大面积高级留白，用于后期放置标题和短文案。整体精致、安静、有东方韵味，淡金色细线作为装饰，色彩高级，细节丰富但不拥挤。

过渡处理：水袖与背景之间使用水墨晕染和半透明色带自然融合，边缘渐变柔和，避免生硬分割线。传统元素与现代几何留白结合，形成杂志广告的高级视觉。
艺术质感，非照片写实，不要真实摄影感，不要出现任何文字。
尺寸：4961x3508像素，300dpi，A4跨页横版比例。
```

Suggested later typography:
- 主标题：水磨腔起，昆韵新生
- 副标题：一曲昆山，唱响千年

## 3. Poster / 招贴设计

Format target:
- A4 vertical
- 1654 × 2339 px at 200dpi, or generate 2480 × 3508 and set/export to required dpi
- Strongest main visual, distant readability, large title, little information.

Prompt:
```text
新中式昆曲插画风格，A4竖版招贴海报主视觉，主题为“百戏之祖，青春开场”。画面中央是一位昆曲人物的动态剪影，水袖大幅展开，像声波、浪潮和水墨云气一样向四周延展，形成强烈视觉冲击。人物造型优雅但不写实，使用工笔线条、扁平色块和半抽象水墨表现。背景融合昆山江南园林窗棂、曲谱符号、折扇形状、昆山水乡桥影，元素以淡墨和几何线条处理，不喧宾夺主。

构图要求：中央主体突出，上方留出大标题空间，下方留出活动信息空间；标题区域背景相对干净，主体水袖形成从下方向上展开的视觉动势。色彩以黛青、胭脂红、墨黑、宣纸米白为主，淡金色细节增强文化高级感。画面要有广告招贴感，远看识别度强，近看有细节。

过渡处理：水袖、声波、水墨背景之间设置柔和边缘渐变，约150到200像素宽的自然晕染过渡带，避免生硬分割线。传统昆曲元素与现代几何版式自然融合。
艺术质感，非照片写实，不要真实摄影感，不要出现任何文字。
尺寸：2480x3508像素，A4竖版比例，适合200dpi或300dpi印刷输出。
```

Suggested later typography:
- 主标题：百戏之祖，青春开场
- 副标题：一曲昆山，唱响千年

## 4. POP ad / POP广告

Format target:
- A5 vertical
- 1748 × 2480 px at 300dpi, or 1165 × 1653 px at 200dpi
- Near-viewing display: shelf card, table card, event standee; needs CTA, QR, time/place area.

Prompt:
```text
新中式昆曲插画风格，A5竖版POP广告构图，主题为“昆曲体验季，邀你入戏”。画面上半部分是一位年轻化表达的昆曲人物或水袖局部插画，水袖形成优雅弧线，引导视线向下。背景为宣纸米白、水墨晕染和江南园林窗棂纹样，加入折扇、曲谱、淡金装饰线和小桥水乡轮廓。画面中下部保留清晰的矩形信息卡片区域，用于后期放置活动时间、地点、二维码和报名方式。整体比杂志广告更活泼、更亲近，适合校园、文创店、展览入口的线下展示。

构图要求：上方主视觉吸引注意，中部留标题空间，下方保留约30%的干净信息区和二维码占位区；信息区背景浅色、边框清晰，便于文字识别。色彩为宣纸米白、黛青、胭脂红、淡金，局部可加入更明亮的月白色提升年轻感。

过渡处理：人物水袖与信息卡片之间用水墨渐变和半透明色带柔和连接，不要硬切割。现代几何卡片与传统昆曲元素融合自然。
艺术质感，非照片写实，不要真实摄影感，不要出现任何文字，不要真实二维码。
尺寸：1748x2480像素，300dpi，A5竖版比例。
```

Suggested later typography:
- 主标题：昆曲体验季 · 邀你入戏
- 副标题：一曲昆山，唱响千年
- 活动点：水袖体验 / 昆曲妆造 / 折扇打卡 / 非遗导赏
- CTA：扫码预约
