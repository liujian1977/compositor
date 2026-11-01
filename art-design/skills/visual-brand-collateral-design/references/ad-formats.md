# Ad format specifications

Common advertising formats with their print requirements and usage contexts.

## Format comparison table

| Format | Dimensions | DPI | Usage | Design emphasis |
|--------|-----------|-----|-------|-----------------|
| 报纸广告 | ~12×18cm (1417×2126px) | 300 | 5-column width, text-dense | Compact layout, high readability, limited color |
| 杂志广告 | A4 spread 420×297mm (4961×3508px) | 300 | Full-page, visual impact | Bold visuals, minimal text, high color fidelity |
| 户外招贴 | 3×4m (1772×2362px @ 150dpi) | 150 | Large format, distant viewing | High contrast, large typography, clear visual hierarchy |
| POP广告 | A5 148×210mm (874×1240px) | 300 | In-store, shelf-level | Concise information, clear call-to-action, recognizable branding |

## Dimension calculations

### A4 standard
- Width: 210mm → 2480px @ 300dpi / 1653px @ 200dpi
- Height: 297mm → 3508px @ 300dpi / 2339px @ 200dpi

### A5 standard (half A4)
- Width: 148mm → 1748px @ 300dpi / 1165px @ 200dpi
- Height: 210mm → 2480px @ 300dpi / 1653px @ 200dpi

### Large format (户外)
- 3m × 4m @ 150dpi: 1772px × 2362px
- Formula: pixels = (meters × 1000 / 25.4) × dpi

## Design considerations by format

### Newspaper ads
- Color limitations: Often black/white or limited 4-color
- Text density: High information density expected
- Visual style: Clean, high contrast, sharp edges
- Layout: Grid-based, text-heavy, clear hierarchy

### Magazine ads
- Color fidelity: Full CMYK, accurate color reproduction
- Visual impact: Emotional connection, artistic treatment
- Print quality: High gloss/matte paper, fine detail reproduction
- Layout: Generous white space, large visuals, minimal text

### Outdoor posters
- Viewing distance: 10m–50m, design for distant readability
- Typography: Extremely large, bold, high contrast
- Color: Saturated, high contrast, works in varying light
- Simplicity: Single strong message, minimal elements

### POP ads
- Viewing distance: 0.5m–2m, detailed information acceptable
- Call-to-action: Clear, prominent pricing/offer information
- Branding: Immediate brand recognition
- Placement: Near product, integrated with shelf context

## Verification checklist

Before final output:
- [ ] Correct dimensions for format
- [ ] Proper DPI for intended use
- [ ] Color mode: RGB for screen/digital, CMYK for print (if conversion needed)
- [ ] File format: PNG (transparency) or JPG (compression)
- [ ] File size: Optimized for distribution but maintains quality
- [ ] Text legibility at intended viewing distance
- [ ] Color contrast meets accessibility standards