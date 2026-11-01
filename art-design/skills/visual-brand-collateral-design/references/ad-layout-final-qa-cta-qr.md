# Ad Layout Final QA: CTA, QR, and Delivery Loops

Lessons from a multi-format Kunqu ad campaign layout refinement.

## Durable rules

1. If a CTA says “扫码 / scan / scan to reserve / scan to participate”, the final artwork must include a visible executable scan entry near the CTA.
   - Do not leave “扫码参与 / 扫码预约” as text-only.
   - Add a real QR code or change the CTA wording to avoid promising a scan action.

2. Pair CTA and QR as one conversion module.
   - Place QR beside, above, or below the CTA within the same visual block.
   - Avoid a button on one side and QR far away on the other side with empty space between them.
   - Label the QR clearly: “扫码预约”, “微信扫码预约”, “扫码入口”, “预约码”.

3. Use a real QR pattern for final delivery, not a decorative placeholder.
   - In PIL workflows, generate one with `qrcode` and paste it using nearest-neighbor resizing.
   - Keep a quiet zone and avoid decorative borders interfering with scanability.
   - If the final URL is not provided, use a placeholder campaign URL only after noting it is a placeholder in the report.

4. Review every format for conversion completion, not only composition beauty.
   - Newspaper, magazine, poster, and POP each need an actionable endpoint if the CTA asks the reader to act.
   - A magazine ad with a CTA button but no QR/URL is a hard delivery defect.
   - A poster saying “扫码参与” with no QR is a hard delivery defect.

5. Check for useless blank gutters created by text panels.
   - If left art and right information panel create a tall white vertical strip, extend/shift the background art under the panel and use a gentle gradient/motif bridge.
   - Large blank gutters are not premium whitespace when they visually split the ad.

6. Iterate with crop-focused QA sheets.
   - Produce a full overview plus crops for known-risk zones: lower CTA/QR band, right information column, POP ticket area, and poster bottom band.
   - Ask vision QA to judge only hard defects: overflow, overlap, dead blank space, missing CTA/QR, severe visual proportion issues, and spec mismatch.

## PIL implementation pattern

```python
import qrcode
from PIL import Image

def make_qr(data='https://example.com/campaign'):
    qr = qrcode.QRCode(
        version=2,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=10,
        border=3,
    )
    qr.add_data(data)
    qr.make(fit=True)
    return qr.make_image(fill_color=(20, 20, 20), back_color=(244, 238, 226)).convert('RGB')

def paste_qr(canvas, box, data='https://example.com/campaign'):
    x0, y0, x1, y1 = box
    size = min(x1 - x0, y1 - y0)
    qr_img = make_qr(data).resize((size, size), Image.Resampling.NEAREST)
    canvas.paste(qr_img, (x0, y0))
```

## Final verification evidence to report

- Final file paths
- Pixel dimensions and DPI for every output
- PPTX slide count and media count
- QA sheet paths
- Visual QA conclusion for hard defects
- Backup directory for pre-change outputs
