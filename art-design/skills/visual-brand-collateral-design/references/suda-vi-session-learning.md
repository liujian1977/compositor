# Session Learning: VI Manual Creation - Suzhou University Project

## User Corrections

### 1. Generated Images Lacked Brand Elements

**Initial Issue:** 
Generated mockups were blank templates without logos, text, or brand colors. Prompt used phrases like "no text no logo, minimalist style, suitable for showing design drafts."

**User Feedback:**
"生成的图片质量不好，只有外形，VI的系统的品牌元素（logo、文字）没有进去"

**Correction:**
Prompts must include explicit brand elements:
- Logo: circular clocktower (钟楼), red (#C41E3A)
- Colors: Soochow Red (#C41E3A), Book Gold (#B8860B), Lake Gray (#B0C4DE), Garden Green (#556B2F)
- Text: "苏州大学" (Chinese), "SOOCHOW UNIVERSITY" (English)
- Style: Jiangnan garden elements (window lattices, water ripples, scrolls, seals)

**Fixed Prompt Example:**
```python
prompt = """苏州大学商务名片设计展示，白色卡片放在浅灰色背景上。卡片左上角印有苏大logo（圆形钟楼图案，红色），下方有"苏州大学"和"SOOCHOW UNIVERSITY"标准字，右侧有联系方式占位文字，使用苏大红色作为强调色，整体设计简约专业，江南学术风格，柔和阴影，高质量摄影，4K分辨率"""
```

### 2. PPT Images Not Properly Positioned

**Initial Issue:**
Images inserted into PPT were not sized or positioned to match page layout.

**User Feedback:**
"图片合成到ppt中的时候，大小和位置没有按照ppt排版调整"

**Correction:**
- Must specify explicit dimensions when inserting images
- Use `Inches` or `Cm` from `pptx.util`
- Implement aspect-ratio preserving helpers: `add_picture_fit()` and `add_picture_cover()`
- Slide configs should map page indices to exact coordinates

## Technical Workarounds

### 1. Missing Dependencies

**Issue:** `ModuleNotFoundError: No module named 'openai'` when using `from openai import OpenAI`

**Fix:** Install with `pip install openai` (python-pptx was already installed)

### 2. Import Name Typo

**Issue:** `ImportError: cannot import name 'RgbColor' from 'pptx.dml.color'`

**Fix:** Use correct casing `RGBColor` (uppercase RGB), not `RgbColor`

### 3. Type Conversion Issues

**Issue:** `value must be an integral type, got <class 'float'>` when calculating image positioning

**Partial Fix:** Cast values to float before division, but final solution required simplification (removed crop logic to avoid API limitations)

## Session Context

**Project:** Suzhou University VI Manual (苏州大学VI手册)
**Project Path:** `/Users/heli/Documents/VI作业/`
**Work Directory:** `/Users/heli/Documents/VI作业/work/`

**Deliverables:**
- 8 branded mockup images generated successfully
- PPT synthesis script created but had runtime issues
- User chose manual approach as alternative

**Asset Types Generated:**
1. Business card (名片)
2. Letter/envelope (信纸信封)
3. Admission letter (录取通知书)
4. Certificate (证书)
5. Recruitment poster (招生海报)
6. Website banner (官网Banner)
7. Clothing (服装)
8. Tote bag (手提袋)

## Notes for Future Sessions

- Always verify brand elements are explicitly included in prompts for VI projects
- Test python-pptx image insertion with explicit positioning before batch processing
- Consider using simpler approach without complex crop logic if API has type limitations
- Provide alternative manual workflow when automated PPT assembly fails