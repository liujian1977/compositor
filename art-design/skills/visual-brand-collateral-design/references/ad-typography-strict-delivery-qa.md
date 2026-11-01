# Ad typography strict delivery QA

Use this reference when the user questions font size, line spacing, or text overlap in multi-format ad deliverables. Treat the concern as a blocking delivery issue, not a subjective polish note.

## Trigger signals

- User asks whether font size is appropriate.
- User reports text overlap, crowded type, or hard-to-read labels.
- A final ad set is about to be delivered and contains CTA/QR modules, bottom information cards, or dense sidebars.

## Required loop

1. Do not rely on full-image overview only.
   - Full previews hide small-font and overlap defects.
   - Generate focused crops for each risk zone: title band, subtitle, bottom cards, CTA/QR area, side information column, POP ticket, and any recently changed panel.

2. Inspect typography as a hard-delivery QA pass.
   Check each crop for:
   - Text overlap between title/subtitle, labels, buttons, QR captions, and decorative borders.
   - Text that is technically inside a box but visually touching the next line or border.
   - Micro-footers or decorative English text that becomes unreadable noise.
   - CTA text too small relative to button size.
   - QR label too small, clipped, or detached from QR.
   - Info-card body text too small for the viewing distance of the medium.

3. Fix with layout changes, not only font changes.
   - Increase title/info-card height when enlarging text.
   - Move subtitle down when title descenders or CJK glyph bounds visually collide.
   - Expand action tickets or reduce nonessential copy before shrinking text too far.
   - Delete nonessential micro-text if it harms readability.
   - Keep CTA and QR as one module with a clear label and quiet zone.

4. Re-render and re-check.
   - Produce a new overview sheet plus focused crop sheets.
   - Run visual QA on both: overview catches global proportion issues; crops catch text defects.
   - Only declare delivery-ready after the pass reports no hard defects.

## Format-specific reminders

- Newspaper ads: small colored card text and micro-footers often fail in print. Prefer fewer, larger lines in bottom cards.
- Magazine sidebars: if a right column becomes dense, extend the panel vertically/horizontally and enlarge modules/CTA/QR labels rather than compressing type.
- POP ads: title/subtitle bands are high risk for visual overlap because POP formats are viewed at distance; give the subtitle a clearly separate baseline. Bottom ticket text, CTA, QR, and QR label must be larger than poster footnotes.
- Posters: if an existing layout is stable, avoid unnecessary aesthetic churn; still verify bottom CTA/QR and title band crops.

## Evidence to save before final delivery

- Final image paths and dimensions/DPI.
- PPTX slide count and media count when a deck is included.
- Overview QA sheet path.
- Focused crop QA sheet paths.
- Written conclusion that each format has no hard defects: overlap, unreadable type, overflow, CTA/QR conflict, distortion, or severe proportion issue.
