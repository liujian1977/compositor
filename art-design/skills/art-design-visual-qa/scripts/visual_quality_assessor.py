#!/usr/bin/env python3
"""视觉质量评估：客观指标(PIL/OpenCV) + 主观评估(多模态 LLM 服务)。

LLM 端点从 ~/.codebuddy/models.json（agent 自带 supportsImages 条目）或
local_config.json 的 llm_endpoints（由 setup.sh 注入）读取，不硬编码任何 key/URL。

用法:
  visual_quality_assessor.py <image> [--style 目标风格] [--use-case 用途]
输出: JSON (overall / dimensions / objective_metrics / defects / passed)
"""
import argparse
import base64
import json
import re
import sys
from io import BytesIO
from pathlib import Path

import numpy as np
import requests
from PIL import Image

CONFIG_FILE = Path.home() / ".codebuddy/assets/art-design/local_config.json"
MODELS_JSON = Path.home() / ".codebuddy/models.json"
MAX_SIDE = 512


def load_endpoints():
    """Image-capable LLM endpoints, in priority order:
    1. llm_endpoints defined in local_config.json (written by setup.sh)
    2. supportsImages entries in ~/.codebuddy/models.json (the agent's own config)
    No URL or API key is hardcoded in this file.
    """
    entries = []

    if CONFIG_FILE.exists():
        try:
            cfg = json.loads(CONFIG_FILE.read_text())
            for m in cfg.get("llm_endpoints", []):
                if m.get("url") and m.get("apiKey"):
                    entries.append((m["url"], m["apiKey"], m.get("id") or m.get("name") or m["url"]))
        except Exception:
            pass

    if MODELS_JSON.exists():
        try:
            cfg = json.loads(MODELS_JSON.read_text())
            for m in cfg.get("models", []):
                if m.get("supportsImages") and m.get("url") and m.get("apiKey"):
                    if m["url"] not in {e[0] for e in entries}:
                        entries.append((m["url"], m["apiKey"], m.get("id") or m.get("name")))
        except Exception:
            pass

    if not entries:
        raise SystemExit(
            "no image-capable model endpoint found. Run setup.sh to set llm_endpoints in "
            "local_config.json, or add supportsImages entries to ~/.codebuddy/models.json")
    return entries


def objective_metrics(path):
    img = Image.open(path).convert("RGB")
    arr = np.array(img)
    gray = np.mean(arr, axis=2)
    # Laplacian variance via pure numpy (no cv2 dependency)
    kernel = np.array([[0, 1, 0], [1, -4, 1], [0, 1, 0]], dtype=float)
    lap = (
        gray[:-2, 1:-1] + gray[2:, 1:-1] + gray[1:-1, :-2] + gray[1:-1, 2:]
        - 4 * gray[1:-1, 1:-1]
    )
    sharpness = float(lap.var())
    hsv = np.array(img.convert("HSV"))
    saturation = float(hsv[:, :, 1].mean()) / 255.0
    w, h = img.size
    res = "1.0" if min(w, h) >= 1024 else "0.8" if min(w, h) >= 512 else "0.6"
    sharp_score = min(1.0, sharpness / 100.0)
    sat_score = min(1.0, saturation / 0.45)
    technical = round((float(res) + sharp_score + sat_score) / 3, 3)
    return {
        "resolution": f"{w}x{h}",
        "sharpness": round(sharpness, 1),
        "saturation": round(saturation, 3),
        "technical_score_0_1": technical,
    }


def b64_image(path):
    img = Image.open(path).convert("RGB")
    if max(img.size) > MAX_SIDE:
        r = MAX_SIDE / max(img.size)
        img = img.resize((int(img.width * r), int(img.height * r)))
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=85)
    return base64.b64encode(buf.getvalue()).decode()


def subjective(entries, img_b64, style, use_case):
    base_prompt = (
        "你是专业视觉质量评审。评估这张图，严格输出 JSON（不要其他内容）：\n"
        '{"style_consistency": 0-100, "aesthetic_appeal": 0-100,'
        ' "defects": [{"type": "技术|艺术", "description": "...", "severity": "低|中|高"}],'
        ' "improvement_suggestions": ["..."]}\n'
        f"目标风格: {style or '未指定（按画面自身风格判断一致性）'}\n"
        f"用途: {use_case or '未指定'}\n"
        "评分依据: 风格一致性=风格统一/色彩和谐/细节层次; 美学=视觉冲击/构图平衡/情感传达/完成度。"
    )
    last_err = None
    for url, key, model in entries:
        payload = {
            "model": model,
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": base_prompt},
                    {"type": "image_url",
                     "image_url": {"url": f"data:image/jpeg;base64,{img_b64}"}},
                ],
            }],
            "max_tokens": 2000,
            "temperature": 0.2,
        }
        try:
            r = requests.post(url, json=payload,
                              headers={"Authorization": f"Bearer {key}",
                                       "Content-Type": "application/json"},
                              timeout=120)
            r.raise_for_status()
            msg = r.json()["choices"][0]["message"]
            text = msg.get("content") or msg.get("reasoning_content") or ""
            m = re.search(r"\{.*\}", text, re.DOTALL)
            if not m:
                raise RuntimeError(f"no JSON in model response: {text[:200]}")
            data = json.loads(m.group())
            data["_judge_endpoint"] = url
            return data
        except Exception as e:  # try next endpoint
            last_err = e
    raise SystemExit(f"all image-capable endpoints failed; last error: {last_err}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--style", default="")
    ap.add_argument("--use-case", default="")
    a = ap.parse_args()

    entries = load_endpoints()
    obj = objective_metrics(a.image)
    subj = subjective(entries, b64_image(a.image), a.style, a.use_case)
    judge = subj.get("_judge_endpoint", "")

    tech = obj["technical_score_0_1"] * 100
    style = float(subj.get("style_consistency", 50))
    aesth = float(subj.get("aesthetic_appeal", 50))
    subjective_avg = (style + aesth) / 2
    overall = round(tech * 0.25 + subjective_avg * 0.75, 1)
    defects = subj.get("defects", [])
    severe = any(d.get("severity") == "高" for d in defects)
    passed = overall >= 80 and style >= 75 and not severe

    out = {
        "image_path": a.image,
        "overall_score": overall,
        "dimensions": {
            "image_quality": round(tech, 1),
            "style_consistency": round(style, 1),
            "aesthetic_appeal": round(aesth, 1),
        },
        "objective_metrics": obj,
        "defects": defects,
        "improvement_suggestions": subj.get("improvement_suggestions", []),
        "passed": passed,
        "judge_endpoint": judge,
    }
    print(json.dumps(out, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
