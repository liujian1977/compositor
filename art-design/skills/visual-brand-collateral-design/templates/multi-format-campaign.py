# Multi-format ad campaign workflow

Template for generating advertising campaigns across multiple formats from a single theme.

## When to use

User requests: "围绕这个主题，生成报纸广告、杂志广告、招贴设计、POP广告" or similar multi-format campaigns.

## Core workflow

```
theme analysis → per-format specification → batch generation → format compliance → organization
```

## 1. Format specifications (do this first)

Define each format's requirements BEFORE generation:

| Format | Dimensions | DPI | Design emphasis |
|--------|-----------|-----|-----------------|
| Newspaper | ~12×18cm (1417×2126px) | 300 | Compact, text-dense, readable |
| Magazine | A4 spread (4961×3508px) | 300 | Full-page, visual impact, bold |
| Outdoor poster | 3×4m (1772×2362px) | 150 | Large type, distant viewing, high contrast |
| POP ad | A5 (874×1240px) | 300 | Shelf-level, concise, clear CTA |

See `references/ad-formats.md` for detailed specifications.

## 2. Per-format prompt engineering

**Base elements consistent across all formats**:
- Theme: "魅力上海·城市印象"
- Style: 新中式插画风格
- Core contrast: 传统与现代交融

**Format-specific adjustments**:

### Newspaper ad prompt
```
报纸广告设计，新中式插画风格，上海城市印象主题。
构图：简洁紧凑，上半部分为微型城市景观（东方明珠塔尖+石库门拱形门），下半部分为文字区域。

视觉元素：
- 左侧：东方明珠电视塔轮廓（简笔画风格）
- 右侧：石库门拱形红门（工笔线条）
- 背景：浅灰色渐变，适合印刷

色彩：以黑、白、灰为主，点缀红色和蓝色，适应报纸印刷要求。
文字区域预留：下半部分60%为白色背景，适合放置正文和联系方式。

风格：新中式简约插画，线条清晰，层次分明。
尺寸：适合报纸5栏宽约12cm×18cm，高分辨率印刷品质。
非照片写实，插画风格。
```

### Magazine ad prompt
```
杂志广告设计，新中式插画风格，上海城市印象主题，全版A4跨页。
构图：气势恢宏，对角线分割，左上陆家嘴天际线，右下石库门弄堂。

陆家嘴部分：现代扁平化色块表现东方明珠和金茂大厦，色彩鲜艳，视觉冲击力强。
石库门部分：工笔线条勾勒传统建筑，水墨晕染效果，东方韵味。

色彩：对比强烈，从深蓝天空到砖褐暖色，渐变过渡自然。
留白：上方1/3留白区，适合放置品牌标题和主文案。
风格：新中式插画，艺术质感强，适合杂志全彩印刷。
尺寸：A4跨页，420×297mm，300dpi印刷品质。
```

### Outdoor poster prompt
```
户外招贴设计，新中式插画风格，上海城市印象主题，大型户外广告。
构图：简洁醒目，视觉中心突出，适合远距离观看。

核心视觉：
- 中央：东方明珠塔与石库门门楣重叠融合
- 背景：水墨晕染天空，从冷蓝到暖灰
- 前景：红色石库门拱门作为视觉框架

文字设计：
- 主标题：超大号字体"魅力上海"，白色，带金色描边
- 副标题："城市印象"，红色书法体
- 留白充足，确保50米外可读

色彩：高对比度，黑金红主色，夜间可见性强。
风格：新中式插画，视觉冲击力强，适合户外大尺寸印刷。
尺寸：3米×4米，150dpi大喷绘品质。
```

### POP ad prompt
```
POP广告设计，新中式插画风格，上海城市印象主题，店内宣传海报。
构图：紧凑集中，信息层级清晰，适合近距离观看。

视觉布局：
- 上部（30%）：标题"魅力上海·城市印象"（红色大字）
- 中部（50%）：核心视觉（东方明珠+石库门组合图标）
- 下部（20%）：活动信息和联系方式

设计元素：
- 简化的东方明珠轮廓（3-4个球体）
- 抽象的石库门拱形门框
- 装饰性金色边框

色彩：红、金、黑三色，醒目易读。
风格：新中式简约图标化设计，识别度高。
尺寸：A5竖版（148×210mm），300dpi印刷品质。
信息简洁，文字清晰，适合货架旁展示。
```

## 3. Batch generation script

```python
import requests
import json
from pathlib import Path

token = 'your_access_token'
api_url = 'https://aistudio.baidu.com/llm/lmapi/v3/images/generations'

# Define format-specific prompts
prompts = {
    'newspaper': newspaper_prompt,
    'magazine': magazine_prompt,
    'poster': poster_prompt,
    'pop': pop_prompt
}

# Define format specifications
specs = {
    'newspaper': {'width': 1417, 'height': 2126, 'dpi': 300},
    'magazine': {'width': 4961, 'height': 3508, 'dpi': 300},
    'poster': {'width': 1772, 'height': 2362, 'dpi': 150},
    'pop': {'width': 874, 'height': 1240, 'dpi': 300}
}

for ad_type, prompt in prompts.items():
    headers = {'Authorization': f'Bearer {token}'}
    payload = {
        'model': 'ERNIE-Image-Turbo',
        'prompt': prompt,
        'response_format': 'url'
    }
    
    resp = requests.post(api_url, headers=headers, json=payload, timeout=60)
    if resp.status_code == 200:
        data = resp.json()
        img_url = data.get('data', [{}])[0].get('url')
        
        # Save meta
        meta_path = Path(f'assets/{ad_type}_ad_meta.json')
        meta_path.write_text(json.dumps({'url': img_url}, ensure_ascii=False), encoding='utf-8')
```

## 4. Format compliance (post-processing)

```python
from PIL import Image
from pathlib import Path

assets_dir = Path('assets')

for ad_type, spec in specs.items():
    # Load generated image
    img_path = assets_dir / f'{ad_type}_ad.png'
    img = Image.open(img_path)
    
    # Resize to format specifications
    resized_img = img.resize((spec['width'], spec['height']), Image.LANCZOS)
    
    # Save with correct DPI
    png_output = assets_dir / f'{ad_type}_ad_final.png'
    resized_img.save(png_output, dpi=(spec['dpi'], spec['dpi']))
    
    jpg_output = assets_dir / f'{ad_type}_ad_final.jpg'
    resized_img_rgb = resized_img.convert('RGB')
    resized_img_rgb.save(jpg_output, quality=95, dpi=(spec['dpi'], spec['dpi']))
```

## 5. Organization structure

```
project/
├── assets/
│   ├── newspaper_ad_final.png/jpg
│   ├── magazine_ad_final.png/jpg
│   ├── poster_ad_final.png/jpg
│   ├── pop_ad_final.png/jpg
│   ├── ads_manifest.json (campaign summary)
│   └── *_ad_meta.json (API responses)
├── newspaper_ad/
│   ├── newspaper_ad_final.png
│   └── newspaper_ad_final.jpg
├── magazine_ad/
│   ├── magazine_ad_final.png
│   └── magazine_ad_final.jpg
├── poster_design/
│   ├── poster_ad_final.png
│   └── poster_ad_final.jpg
└── pop_ad/
    ├── pop_ad_final.png
    └── pop_ad_final.jpg
```

## 6. Campaign manifest template

```json
{
  "project": "魅力上海·城市印象广告设计系列",
  "theme": "传统与现代交融（石库门与陆家嘴）",
  "style": "新中式插画风格",
  "ads": [
    {
      "type": "报纸广告",
      "file_png": "newspaper_ad_final.png",
      "file_jpg": "newspaper_ad_final.jpg",
      "specs": "约12cm×18cm，300dpi",
      "usage": "报纸5栏宽幅，适合文字密集内容"
    },
    {
      "type": "杂志广告",
      "file_png": "magazine_ad_final.png",
      "file_jpg": "magazine_ad_final.jpg",
      "specs": "A4跨页420×297mm，300dpi",
      "usage": "杂志全彩大版面，视觉冲击力强"
    },
    {
      "type": "招贴设计",
      "file_png": "poster_ad_final.png",
      "file_jpg": "poster_ad_final.jpg",
      "specs": "3×4米，150dpi",
      "usage": "户外大型广告，远距离可读"
    },
    {
      "type": "POP广告",
      "file_png": "pop_ad_final.png",
      "file_jpg": "pop_ad_final.jpg",
      "specs": "A5 148×210mm，300dpi",
      "usage": "店内宣传，信息简洁，货架旁展示"
    }
  ],
  "notes": "四种广告类型围绕同一主题，采用新中式插画风格，根据不同媒介特点调整规格和设计重点"
}
```

## Verification checklist

Per format, verify:
- [ ] Correct dimensions for format
- [ ] Proper DPI for intended use
- [ ] Style consistency with campaign theme
- [ ] Appropriate visual weight for medium
- [ ] Text legibility at viewing distance
- [ ] File naming convention followed

## Common pitfalls

1. **Ignoring format-specific design needs**
   - Signal: All ads look the same despite different use contexts
   - Fix: Adjust visual complexity, text density, and scale per format

2. **Incorrect format specifications**
   - Signal: Images have wrong dimensions or DPI
   - Fix: Use format-specific dimension calculations (see `references/ad-formats.md`)

3. **Forgetting to copy files to format directories**
   - Signal: User asks "把文件拷贝到上级目录" or similar
   - Fix: Copy final files to both assets/ and format-specific directories

4. **Inconsistent naming across formats**
   - Signal: Confusing file names, hard to track versions
   - Fix: Use consistent naming: `{format}_ad_final.{ext}`