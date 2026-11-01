#!/usr/bin/env python3
"""
PIL-based VI Mockup Generator
Generates application mockups using real official logo assets

Advantages:
- 100% logo accuracy (uses actual logo file)
- Fast (<1 second per image)
- Stable output
- PPT-optimized file sizes
- No API costs or rate limits

Usage:
    python generate_vi_mockups.py
"""

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

# ============== CONFIGURATION ==============

# Path to official logo (PNG with transparency preferred)
LOGO_PATH = "official_logo.png"

# Output directory
OUTPUT_DIR = "work/assets/pil_vi_mockups"

# ============== APPLICATION SPECIFICATIONS ==============
# Sizes are optimized for PPT use (not 4K+)
# Adjust logo_size and position per application

SPECS = {
    "business_card": {
        "name": "名片",
        "size": (1050, 600),  # 16:9 ratio for PPT
        "logo_size": (150, 150),
        "logo_position": (100, 150),
        "background_color": (255, 255, 255),  # White
        "text": "苏州大学 | Soochow University",
        "text_position": (300, 200),
        "border": True
    },
    
    "letterhead": {
        "name": "信纸",
        "size": (1050, 1480),  # A4 ratio
        "logo_size": (100, 100),
        "logo_position": (50, 50),
        "background_color": (255, 255, 255),  # White
        "text": "苏州大学信纸",
        "text_position": (180, 80),
        "border": True
    },
    
    "admission_letter": {
        "name": "录取通知书",
        "size": (1050, 1480),  # A4 ratio
        "logo_size": (180, 180),
        "logo_position": (435, 100),  # Centered top
        "background_color": (255, 248, 220),  # Cream/mi-yellow
        "text": "录取通知书",
        "text_position": (425, 350),
        "border": True
    },
    
    "certificate": {
        "name": "荣誉证书",
        "size": (1050, 740),  # Landscape certificate
        "logo_size": (200, 200),
        "logo_position": (425, 80),  # Centered top
        "background_color": (255, 250, 240),  # Off-white
        "text": "荣誉证书",
        "text_position": (425, 350),
        "border": True
    },
    
    "poster": {
        "name": "招生海报",
        "size": (740, 1050),  # Vertical poster
        "logo_size": (200, 200),
        "logo_position": (270, 80),  # Centered top
        "background_color": (220, 235, 245),  # Light blue
        "text": "苏州大学招生简章",
        "text_position": (120, 350),
        "border": True
    },
    
    "tote_bag": {
        "name": "手提袋",
        "size": (900, 1000),
        "logo_size": (250, 250),
        "logo_position": (325, 150),  # Centered
        "background_color": (196, 30, 58),  # Brand red (example)
        "text": "苏州大学",
        "text_position": (350, 500),
        "border": True
    },
    
    "banner": {
        "name": "官网Banner",
        "size": (1200, 300),  # 4:1 ratio
        "logo_size": (100, 100),
        "logo_position": (50, 100),
        "background_color": (30, 60, 90),  # Dark blue
        "text": "Soochow University",
        "text_position": (200, 130),
        "border": True
    },
    
    "flag": {
        "name": "旗帜",
        "size": (900, 600),  # 3:2 flag ratio
        "logo_size": (250, 250),
        "logo_position": (325, 100),  # Centered
        "background_color": (180, 40, 40),  # Deep red
        "text": "苏州大学",
        "text_position": (370, 400),
        "border": True
    },
    
    "signage": {
        "name": "导视牌",
        "size": (800, 400),  # Landscape sign
        "logo_size": (120, 120),
        "logo_position": (50, 50),
        "background_color": (255, 255, 255),  # White
        "text": "苏州大学导视牌",
        "text_position": (200, 100),
        "border": True
    },
    
    "clothing": {
        "name": "文化衫",
        "size": (600, 700),  # T-shirt ratio
        "logo_size": (150, 150),
        "logo_position": (225, 150),  # Chest position
        "background_color": (240, 240, 240),  # Light gray
        "text": "苏州大学",
        "text_position": (150, 350),
        "border": True
    }
}

# ============== GENERATION LOGIC ==============

def generate_mockup(spec_name, spec, logo, output_dir):
    """Generate a single mockup"""
    
    # Create background
    bg = Image.new('RGB', spec["size"], spec["background_color"])
    draw = ImageDraw.Draw(bg)
    
    # Add border (professional look)
    if spec.get("border", False):
        border_color = (180, 180, 180)
        draw.rectangle(
            [10, 10, spec["size"][0]-10, spec["size"][1]-10],
            outline=border_color,
            width=2
        )
    
    # Resize and position logo
    logo_resized = logo.resize(spec["logo_size"], Image.Resampling.LANCZOS)
    
    # Paste logo (with alpha if available)
    if logo_resized.mode == 'RGBA':
        bg.paste(logo_resized, spec["logo_position"], logo_resized)
    else:
        bg.paste(logo_resized, spec["logo_position"])
    
    # Add text (placeholder, gray color to indicate template)
    try:
        # Try system font (macOS/Linux/Windows)
        font_paths = [
            "/System/Library/Fonts/PingFang.ttc",  # macOS
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",  # Linux
            "C:/Windows/Fonts/arial.ttf"  # Windows
        ]
        
        font = None
        for font_path in font_paths:
            if Path(font_path).exists():
                font = ImageFont.truetype(font_path, 24)
                break
        
        if font:
            draw.text(
                spec["text_position"],
                spec.get("text", ""),
                fill=(100, 100, 100),
                font=font
            )
    except Exception as e:
        # Fallback to default font
        draw.text(
            spec["text_position"],
            spec.get("text", ""),
            fill=(100, 100, 100)
        )
    
    # Save
    output_path = output_dir / f"{spec_name}_with_real_logo.png"
    bg.save(output_path, "PNG", optimize=True)
    
    return output_path

def main():
    """Main generation loop"""
    
    # Create output directory
    output_dir = Path(OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Load logo
    logo_path = Path(LOGO_PATH)
    if not logo_path.exists():
        print(f"✗ Error: Logo file not found: {logo_path}")
        print("  Please update LOGO_PATH in the script")
        return
    
    logo = Image.open(logo_path)
    
    # Convert to RGBA if needed
    if logo.mode != 'RGBA':
        logo = logo.convert('RGBA')
    
    print(f"=== PIL VI Mockup Generator ===")
    print(f"Logo: {logo_path} ({logo.size[0]}x{logo.size[1]})")
    print(f"Output: {output_dir}")
    print()
    
    # Generate all mockups
    results = []
    for spec_name, spec in SPECS.items():
        try:
            output_path = generate_mockup(spec_name, spec, logo, output_dir)
            file_size = output_path.stat().st_size / 1024
            
            print(f"✓ {spec['name']:12s} → {output_path.name} ({file_size:6.1f} KB)")
            
            results.append({
                "name": f"{spec['name']}（使用真实校徽）",
                "status": "success",
                "file": str(output_path),
                "size_kb": round(file_size, 1)
            })
            
        except Exception as e:
            print(f"✗ {spec['name']:12s} → Error: {e}")
            results.append({
                "name": f"{spec['name']}（使用真实校徽）",
                "status": "failed",
                "error": str(e)
            })
    
    # Save results
    result_file = output_dir / "generation_results.json"
    with open(result_file, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    
    # Summary
    success_count = sum(1 for r in results if r["status"] == "success")
    print()
    print(f"=== Complete ===")
    print(f"Generated: {success_count}/{len(SPECS)}")
    print(f"Results saved to: {result_file}")
    print(f"Images saved to: {output_dir}")

if __name__ == "__main__":
    main()