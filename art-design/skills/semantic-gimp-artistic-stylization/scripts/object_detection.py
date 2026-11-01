#!/usr/bin/env python3
"""Object detection via YOLOv8n -> JSON. Adapted for CodeBuddy art-design skills."""
import sys, json
from pathlib import Path
from ultralytics import YOLO

WEIGHTS = Path.home() / ".codebuddy/assets/art-design/yolov8n.pt"

def detect(image_path, conf=0.5, fmt="json", verbose=False):
    try:
        model = YOLO(str(WEIGHTS) if WEIGHTS.exists() else "yolov8n.pt")
        results = model(str(image_path), conf=conf, verbose=False)
        detections = []
        for r in results:
            for box in r.boxes:
                x1, y1, x2, y2 = box.xyxy[0].tolist()
                cid = int(box.cls[0])
                detections.append({
                    "class_id": cid,
                    "class_name": r.names[cid],
                    "confidence": round(float(box.conf[0]), 3),
                    "bbox": {"x1": round(x1, 1), "y1": round(y1, 1),
                             "x2": round(x2, 1), "y2": round(y2, 1),
                             "width": round(x2 - x1, 1), "height": round(y2 - y1, 1),
                             "center_x": round((x1 + x2) / 2, 1),
                             "center_y": round((y1 + y2) / 2, 1)},
                })
        info = {"image_path": str(image_path),
                "image_size": list(results[0].orig_shape),
                "detections": detections,
                "total_objects": len(detections)}
        return json.dumps(info, indent=2, ensure_ascii=False)
    except Exception as e:
        return json.dumps({"error": str(e), "image_path": str(image_path)}, ensure_ascii=False)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: object_detection.py <image> [conf] [json|text]")
        sys.exit(1)
    conf = float(sys.argv[2]) if len(sys.argv) > 2 else 0.5
    print(detect(sys.argv[1], conf))
