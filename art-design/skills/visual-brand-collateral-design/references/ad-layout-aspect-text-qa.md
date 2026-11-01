# Ad layout: aspect-ratio-safe image placement + typography QA

Use this reference when generated ad base images are good, but final newspaper/POP/poster/magazine layouts look distorted or text panels collide with the art.

## Durable lessons

1. Never stretch AI base art into a different final ratio.
   - Many text-to-image systems return square-ish images even when the prompt asks for tall/wide print specs.
   - Direct `resize(base, final_size)` causes visible horizontal/vertical compression.
   - Use aspect-ratio-preserving `cover + crop` for visual regions, or `contain + designed margins` when cropping would lose key subject matter.

2. Keep typography panels separate from the main subject.
   - Avoid large semi-opaque text rectangles over the face/body/sleeve/primary illustration.
   - Prefer editorial text columns, title bands, bottom info cards, or sidebars.
   - For newspaper ads, a safe pattern is left visual + right text column.
   - For POP ads, a safe pattern is top visual + middle title strip + bottom info/QR card.

3. Generated bases may already contain unwanted card-like shapes.
   - If a base prompt requested “information area” or “QR placeholder,” the generated image may include a white/cream rectangle inside the art.
   - Do not import that region into the final main visual if you will add your own text card later.
   - First diagnose the base image itself: create a quick crop/contact sheet comparing top 55%, 62%, 70%, 78%, and 100% (or equivalent crop bands) plus the current final.
   - Choose the largest clean crop that excludes the generated blank/card region while preserving the subject and key decorations, then use that cropped base for aspect-safe placement.
   - For POP layouts, a common fix is: crop the source base to the clean top ~60–65% before cover placement, then add the real title/info/QR cards outside the main visual.
   - If no clean crop exists, regenerate with a prompt that forbids text boxes/cards in the main visual.

4. When subject integrity beats maximum fill, use contain instead of cover.
   - Cover/crop enlarges the art but can cut off sleeves, hands, logos, or other important subject edges.
   - If repeated cover tuning still clips a key subject, switch that visual region to aspect-ratio-preserving contain/fit with intentional paper-colored padding or a wider frame.
   - For newspaper-style layouts, a safe fallback is a wider left visual frame using contain placement plus a narrower but still readable right editorial column.

5. Text fitting must be programmatic, not eyeballed.
   - Use a text measurement loop (`textbbox`) to shrink font size until each line fits the panel.
   - Wrap Chinese/mixed text by character when necessary.
   - Enforce inner padding and right/bottom bounds for every text block.

## Minimal PIL patterns

Aspect-ratio preserving cover/crop:

```python
def cover_resize_crop(img, box_size, focus=(0.5, 0.45)):
    tw, th = box_size
    iw, ih = img.size
    scale = max(tw / iw, th / ih)
    nw, nh = round(iw * scale), round(ih * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    fx, fy = focus
    left = int(max(0, min(nw - tw, nw * fx - tw / 2))) if nw > tw else 0
    top = int(max(0, min(nh - th, nh * fy - th / 2))) if nh > th else 0
    return resized.crop((left, top, left + tw, top + th))
```

Aspect-ratio preserving contain/fit (use when subject must not be cropped):

```python
def contain_resize_fit(img, box_size, fill=(246, 240, 228)):
    tw, th = box_size
    iw, ih = img.size
    scale = min(tw / iw, th / ih)
    nw, nh = round(iw * scale), round(ih * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    fitted = Image.new("RGB", (tw, th), fill)
    fitted.paste(resized, ((tw - nw) // 2, (th - nh) // 2))
    return fitted
```

Diagnose unwanted generated cards before layout fixes:

```python
def crop_diagnosis_sheet(base, final=None, out="crop_diagnosis.jpg"):
    parts = []
    for pct in [0.55, 0.62, 0.70, 0.78, 1.0]:
        crop = base.crop((0, 0, base.width, int(base.height * pct)))
        crop.thumbnail((300, 360), Image.Resampling.LANCZOS)
        parts.append((f"base top {pct:.0%}", crop.copy()))
    if final is not None:
        thumb = final.copy()
        thumb.thumbnail((300, 520), Image.Resampling.LANCZOS)
        parts.append(("current final", thumb))
    # paste thumbnails into a labeled contact sheet, then inspect which crop avoids the blank/card region.
```

Chinese-safe wrapping:

```python
def wrap_cjk(draw, text, font, max_width):
    lines, cur = [], ""
    for ch in text:
        trial = cur + ch
        if cur and draw.textbbox((0, 0), trial, font=font)[2] > max_width:
            lines.append(cur)
            cur = ch
        else:
            cur = trial
    if cur:
        lines.append(cur)
    return lines
```

Font shrink-to-fit:

```python
def fit_font_for_width(draw, text, font_path, start_size, max_width, min_size=18):
    for size in range(start_size, min_size - 1, -2):
        font = ImageFont.truetype(font_path, size)
        if draw.textbbox((0, 0), text, font=font)[2] <= max_width:
            return font
    return ImageFont.truetype(font_path, min_size)
```

## Required self-QA before declaring success

Create a QA/contact sheet with full previews and focused crops:
- newspaper full image
- newspaper text-panel crop
- POP full image
- POP main-visual crop
- any panel/subject crop that was recently corrected

Inspect against explicit rules:
1. Newspaper text is fully inside the image and inside its panel; no right-edge or bottom overflow.
2. POP main visual contains only the intended illustration; no unwanted large white/card/text-background rectangle.
3. Typography and decorations do not seriously overlap.
4. Margins are reasonable; no important text or subject is clipped.
5. Final JPG/PNG dimensions and DPI match the assignment specs.
6. PPTX opens and contains the expected slide count.

Record the QA result in a report/checkpoint when the task is checkpointed.