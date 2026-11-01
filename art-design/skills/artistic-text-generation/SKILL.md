---
name: artistic-text-generation
description: Generate artistic Chinese text (艺术字) using PIL/Pillow and GIMP script-fu. Covers stroke, shadow, gradient, seal/stamp effects, and text compositing onto backgrounds. Use when user needs decorative titles, seal stamps, or stylized text for posters/illustrations.
---

# Artistic Text Generation (艺术字生成)

为海报/插画生成装饰性中文文字。PIL 做简单效果（首选），GIMP script-fu 做复杂合成。**永远不要用扩散模型（ImageGen）生成中文文字——准确率接近零。**

## 何时用

- 海报主标题/副标题、"艺术字"、"印章"、"落款"
- 给 AI 生成图加中文文字（正确路线：先生成无文字背景 → PIL 生成透明底艺术字 → compositor/GIMP 合成）

## 不用

- 精确书法复刻（需真实书法字体）
- 文字为主要内容的专业排版（用排版工具）

## PIL 主路线（~/.venv-art/bin/python）

```python
from PIL import Image, ImageDraw, ImageFont

FONTS = {
    "heiti_medium": "/System/Library/Fonts/STHeiti Medium.ttc",
    "heiti_light": "/System/Library/Fonts/STHeiti Light.ttc",
    "hiragino": "/System/Library/Fonts/Hiragino Sans GB.ttc",
    "songti": "/System/Library/Fonts/Supplemental/Songti.ttc",
}

def create_text_image(text, font_path, font_size, effect="stroke", **kw):
    font = ImageFont.truetype(font_path, font_size)
    bbox = font.getbbox(text)
    w, h = bbox[2]-bbox[0]+40, bbox[3]-bbox[1]+40
    img = Image.new('RGBA', (w, h), (0,0,0,0))
    d = ImageDraw.Draw(img)
    if effect == "stroke":     # 描边标题
        d.text((20,20), text, font=font, fill=kw.get("fill_color",(200,30,30)),
               stroke_width=kw.get("stroke_width",4), stroke_fill=kw.get("stroke_color",(255,215,0)))
    elif effect == "shadow":   # 阴影
        off = kw.get("offset",5)
        d.text((20+off,20+off), text, font=font, fill=kw.get("shadow_color",(0,0,0,80)))
        d.text((20,20), text, font=font, fill=kw.get("fill_color",(200,30,30)))
    elif effect == "seal":     # 印章
        d.rectangle([5,5,w-5,h-5], fill=(220,40,40,200), outline=kw.get("border_color",(180,20,20)), width=3)
        d.text((20,20), text, font=font, fill=kw.get("fill_color",(180,20,20)))
    elif effect == "gradient": # 渐变（多层叠加）
        for i,c in enumerate(kw.get("colors",[(200,30,30),(255,200,30)])):
            d.text((20,20+i*2), text, font=font, fill=c)
    return img
```

配方：国风印章=seal+songti+朱砂红；海报主标题=stroke+heiti_medium+红字金边；水墨=shadow+songti+墨色。

## 合成到背景

```bash
# compositor 叠加（透明底 PNG 贴到指定位置）
${COMPOSITOR_BIN:-$HOME/.codebuddy/bin/compositor} composite \
  --base background.png --overlay title.png --x X --y Y --out final.png
```

或 GIMP script-fu 多层（见 gimp-layered-psd-cli/scripts/assemble_layers.sh）。

## GIMP 文字层（script-fu 2.10）

```scheme
(gimp-image-insert-layer img
  (car (gimp-text-fontname img -1 100 80 "端午安康" 0 TRUE 200 "STHeiti Medium" '(0.78 0.12 0.12 1)))
  0 -1)
```

## 工作流集成

```
Phase 4 提示词 → 背景预留文字区（prompt 里写 "clear empty space at top for title"，avoid 任何文字/字母）
Phase 5 加工   → ImageGen 背景 → PIL 艺术字透明 PNG → compositor/GIMP 合成
Phase 6 评估   → ViewImage 检查可读性/对比度（深底浅字、浅底深字，必要时描边）
```

## Pitfalls

1. 系统字体覆盖常用汉字，生僻字缺失；书法字体需用户自行安装
2. PIL stroke_width 需 Pillow ≥9（venv-art 满足）
3. GIMP 批处理必须带兜底 `-b "(gimp-quit 0)"`
4. 字体授权：系统字体自由用，自装字体查授权
