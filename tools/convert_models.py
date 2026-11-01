#!/usr/bin/env python3
"""
Model Conversion Script — Convert ONNX models to Core ML (.mlpackage).

Converts the three ONNX models used by the Compositor CLI into Apple Core ML
mlprogram packages, following the pipeline proven on this machine:

    onnx.load → onnxsim.simplify → (Clip patch) → onnx2torch → torch.jit.trace
    → ct.convert(mlprogram, ImageType/TensorType inputs, TensorType outputs)

Why the ONNX frontend is NOT used: coremltools >= 8 dropped the ONNX
converter frontend entirely, so ONNX models must be routed through
onnx2torch + TorchScript.

Usage:
    python3 convert_models.py                     # convert everything
    python3 convert_models.py rtmpose             # pose model only
    python3 convert_models.py insightface         # inswapper + recognition
    python3 convert_models.py insightface --no-download

Requirements (Python 3.11 recommended — wheels for 3.13 may lack native libs):
    pip install coremltools==8.0 torch onnx onnxsim onnx2torch Pillow

Model sources (verified working URLs):
    RTMPose  : https://www.modelscope.cn/models/AXERA-TECH/RTMPose/resolve/master/rtmpose_m_256x192.onnx
    inswapper: https://github.com/deepinsight/insightface/releases/download/v0.7/inswapper_128.onnx
    ArcFace  : https://huggingface.co/public-data/insightface/resolve/main/models/buffalo_l/w600k_r50.onnx

Converted outputs land in ~/Library/Application Support/Compositor/models-ml/
(notes: CoreML loads .mlpackage via MLModel.compileModel; Swift caches the
compiled .mlmodelc under models-ml/.compiled/).
"""

import argparse
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

# ─── Constants ─────────────────────────────────────────────────────────

MODELS_DIR = Path.home() / "Library" / "Application Support" / "Compositor" / "models-ml"

SOURCES = {
    "rtmpose": "https://www.modelscope.cn/models/AXERA-TECH/RTMPose/resolve/master/rtmpose_m_256x192.onnx",
    "inswapper": "https://github.com/deepinsight/insightface/releases/download/v0.7/inswapper_128.onnx",
    "recognition": "https://huggingface.co/public-data/insightface/resolve/main/models/buffalo_l/w600k_r50.onnx",
}

# ImageNet normalization (RGB order) used by RTMPose preprocessing.
POSE_MEAN = [123.675, 116.28, 103.53]
POSE_STD = [58.395, 57.12, 57.375]
# ArcFace recognition normalization: (x - 127.5) / 127.5
REC_MEAN = [127.5, 127.5, 127.5]
REC_STD = [127.5, 127.5, 127.5]


def download(url: str, out: Path) -> bool:
    print(f"  Downloading {url}")
    try:
        with urllib.request.urlopen(url, timeout=300) as resp, open(out, "wb") as f:
            f.write(resp.read())
        print(f"  Saved {out} ({out.stat().st_size / 1e6:.1f} MB)")
        return True
    except Exception as e:
        print(f"  Download failed: {e}")
        return False


def simplify(onnx_path: Path, out_path: Path) -> Optional[Path]:
    """Run onnxsim and patch Clip nodes whose 'max' input is empty.

    RTMPose's exported Clip has an empty max operand which crashes onnx2torch
    (dynamic-max KeyError). Deleting the empty operand makes onnx2torch treat
    max as None, which is the correct semantics.
    """
    import onnx
    from onnxsim import simplify as onnx_simplify

    model = onnx.load(str(onnx_path))
    model_ok, _ = onnx_simplify(model)
    if not model_ok:
        print("  WARNING: onnxsim returned an unsimplified model; continuing with original")
    patched = 0
    for node in model.graph.node:
        if node.op_type == "Clip" and len(node.input) == 3 and node.input[2] == "":
            del node.input[2]
            patched += 1
    if patched:
        print(f"  Patched {patched} Clip node(s) with empty max input")
    onnx.save(model, str(out_path))
    return out_path


def _norm_module(inner, mean, std):
    """Wrap a torch module so it accepts raw 0..255 float pixels and applies
    channel-wise (x - mean)/std internally (baked into the traced graph)."""
    import numpy as np
    import torch

    class Wrapped(torch.nn.Module):
        def __init__(self):
            super().__init__()
            self.inner = inner
            self.register_buffer("mean", torch.from_numpy(np.array(mean, dtype=np.float32)).view(1, 3, 1, 1))
            self.register_buffer("std", torch.from_numpy(np.array(std, dtype=np.float32)).view(1, 3, 1, 1))

        def forward(self, x):
            return self.inner((x - self.mean) / self.std)

    return Wrapped()


# ─── Converters ────────────────────────────────────────────────────────

def convert_rtmpose(models_dir: Path, download_source: bool) -> Optional[Path]:
    """RTMPose-m 192x256 (SimCC head) → pose-rtmpose.mlpackage (FP16).

    Input:  ct.ImageType "image" (1,3,256,192), raw RGB 0..255 (scale=1.0);
            ImageNet norm is applied inside the traced module.
    Output: simcc_x [1,17,384], simcc_y [1,17,512] (TensorType-named).
    """
    import numpy as np
    import torch
    import onnx
    from onnx2torch import convert as onnx2torch_convert
    import coremltools as ct

    dst = models_dir / "pose-rtmpose.mlpackage"
    if dst.exists():
        print(f"[SKIP] already exists: {dst}")
        return dst

    onnx_file = models_dir / "rtmpose_m_256x192.onnx"
    if download_source and not onnx_file.exists():
        if not download(SOURCES["rtmpose"], onnx_file):
            return None
    if not onnx_file.exists():
        print(f"ERROR: {onnx_file} not found (use --no-download only with a local copy)")
        return None

    fixed = models_dir / "rtmpose_fixed.onnx"
    simplify(onnx_file, fixed)

    module = onnx2torch_convert(onnx.load(str(fixed)))
    module.eval()
    wrapped = _norm_module(module, POSE_MEAN, POSE_STD).eval()

    raw = np.random.default_rng(3).integers(0, 256, size=(256, 192, 3)).astype(np.float32)
    raw_t = torch.from_numpy(np.ascontiguousarray(np.transpose(raw, (2, 0, 1))[None]))
    with torch.no_grad():
        ref = wrapped(raw_t)
    traced = torch.jit.trace(wrapped, raw_t)
    traced.eval()

    print("  Converting (mlprogram, FP16, macOS14)...")
    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=(1, 3, 256, 192), color_layout="RGB",
                             bias=[0.0, 0.0, 0.0], scale=1.0)],
        outputs=[ct.TensorType(name="simcc_x"), ct.TensorType(name="simcc_y")],
        convert_to="mlprogram",
        compute_precision=ct.precision.FLOAT16,
        minimum_deployment_target=ct.target.macOS14,
    )
    mlmodel.save(str(dst))
    _verify(dst, {"image": raw}, [ref[0].numpy(), ref[1].numpy()], ["simcc_x", "simcc_y"])
    fixed.unlink(missing_ok=True)
    onnx_file.unlink(missing_ok=True)
    _manifest(models_dir, "pose-rtmpose", "pose_estimation", (192, 256),
             "RTMPose-m body keypoints (COCO-17), SimCC head, 192x256 input")
    print(f"[SUCCESS] {dst}")
    return dst


def convert_insightface(models_dir: Path, download_source: bool) -> Optional[Path]:
    """inswapper_128 + w600k_r50 → face-swap-insightface.mlpackage (FP32)
    + face-recognition-insightface.mlpackage (FP16).

    inswapper:  ImageType "target" (1,3,128,128) scale=1/255 (graph expects
                [0,1]); TensorType "source" (1,512) embedding. Output "output".
    recognition: ImageType "image" (1,3,112,112) raw 0..255 with (x-127.5)/127.5
                baked into the traced module. Output "embedding" (1,512).
    """
    import numpy as np
    import torch
    import onnx
    from onnx2torch import convert as onnx2torch_convert
    import coremltools as ct

    swap_dst = models_dir / "face-swap-insightface.mlpackage"
    rec_dst = models_dir / "face-recognition-insightface.mlpackage"

    # ── recognition ──
    if not rec_dst.exists():
        onnx_file = models_dir / "w600k_r50.onnx"
        if download_source and not onnx_file.exists():
            if not download(SOURCES["recognition"], onnx_file):
                return None
        if not onnx_file.exists():
            print(f"ERROR: {onnx_file} not found")
            return None
        rm = onnx2torch_convert(onnx.load(str(onnx_file)))
        rm.eval()
        wr = _norm_module(rm, REC_MEAN, REC_STD).eval()
        raw = np.random.default_rng(1).integers(0, 256, size=(112, 112, 3)).astype(np.float32)
        raw_t = torch.from_numpy(np.ascontiguousarray(np.transpose(raw, (2, 0, 1))[None]))
        with torch.no_grad():
            ref_emb = wr(raw_t)
        traced = torch.jit.trace(wr, raw_t)
        traced.eval()
        print("  Converting recognition model (mlprogram, FP16)...")
        mrec = ct.convert(
            traced,
            inputs=[ct.ImageType(name="image", shape=(1, 3, 112, 112), color_layout="RGB",
                                 bias=[0.0, 0.0, 0.0], scale=1.0)],
            outputs=[ct.TensorType(name="embedding")],
            convert_to="mlprogram",
            compute_precision=ct.precision.FLOAT16,
            minimum_deployment_target=ct.target.macOS14,
        )
        mrec.save(str(rec_dst))
        emb_ref = ref_emb.numpy()
        _verify(rec_dst, {"image": raw}, [emb_ref], ["embedding"])
        onnx_file.unlink(missing_ok=True)
        _manifest(models_dir, "face-recognition-insightface", "face_recognition", (112, 112),
                  "ArcFace w600k_r50 embedding (512-d)")
        print(f"[SUCCESS] {rec_dst}")
    else:
        print(f"[SKIP] already exists: {rec_dst}")

    # ── inswapper ──
    if not swap_dst.exists():
        onnx_file = models_dir / "inswapper_128.onnx"
        if download_source and not onnx_file.exists():
            if not download(SOURCES["inswapper"], onnx_file):
                return None
        if not onnx_file.exists():
            print(f"ERROR: {onnx_file} not found")
            return None
        tm = onnx2torch_convert(onnx.load(str(onnx_file)))
        tm.eval()
        t = torch.rand(1, 3, 128, 128)
        s = torch.rand(1, 512)
        traced = torch.jit.trace(tm, (t, s))
        traced.eval()
        print("  Converting inswapper (mlprogram, FP32)...")
        mswap = ct.convert(
            traced,
            inputs=[ct.ImageType(name="target", shape=(1, 3, 128, 128), color_layout="RGB",
                                 bias=[0.0, 0.0, 0.0], scale=1.0 / 255.0),
                    ct.TensorType(name="source", shape=(1, 512))],
            outputs=[ct.TensorType(name="output")],
            convert_to="mlprogram",
            compute_precision=ct.precision.FLOAT32,
            minimum_deployment_target=ct.target.macOS14,
        )
        mswap.save(str(swap_dst))
        onnx_file.unlink(missing_ok=True)
        _manifest(models_dir, "face-swap-insightface", "face_swap", (128, 128),
                  "inswapper_128 face swapper (target image + 512-d source embedding)")
        print(f"[SUCCESS] {swap_dst}")
    else:
        print(f"[SKIP] already exists: {swap_dst}")

    return swap_dst


def _verify(mlpackage: Path, raw_input: dict, refs: list, out_names: list) -> None:
    """CPU-only sanity check of the saved package against the torch reference."""
    import numpy as np
    import coremltools as ct
    from PIL import Image

    try:
        model = ct.models.MLModel(str(mlpackage), compute_units=ct.ComputeUnit.CPU_ONLY)
        feed = {}
        for k, v in raw_input.items():
            feed[k] = Image.fromarray(v.astype(np.uint8), "RGB")
        out = model.predict(feed)
        worst = 0.0
        for name, ref in zip(out_names, refs):
            d = float(np.abs(np.array(out[name]) - ref).max())
            worst = max(worst, d)
            print(f"  Verification: max diff {name}={d:.4f}")
        if worst > 0.2:
            print("  WARNING: large deviation from reference — inspect before use")
    except Exception as e:
        print(f"  (verification skipped: {e})")


def _manifest(models_dir: Path, key: str, mtype: str, input_size: tuple, description: str) -> None:
    manifest_file = models_dir / "models-ml-manifest.json"
    manifest = json.loads(manifest_file.read_text()) if manifest_file.exists() else {"models": {}}
    manifest.setdefault("models", {})[key] = {
        "package": f"{key}.mlpackage",
        "type": mtype,
        "input_size": list(input_size),
        "description": description,
        "converted_at": datetime.now(timezone.utc).isoformat(),
    }
    manifest_file.write_text(json.dumps(manifest, indent=2, ensure_ascii=False))


# ─── CLI ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("models", nargs="*",
                        help="Models to convert: rtmpose, insightface, all (default: all)")
    parser.add_argument("--all", action="store_true", help="Convert all models (default)")
    parser.add_argument("--no-download", action="store_true",
                        help="Use ONNX files already present in the output directory")
    parser.add_argument("--output-dir", type=str, default=None,
                        help=f"Output directory (default: {MODELS_DIR})")
    args = parser.parse_args()

    models_dir = Path(args.output_dir) if args.output_dir else MODELS_DIR
    models_dir.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {models_dir}")

    for pkg in ("coremltools", "torch", "onnx", "onnxsim", "onnx2torch", "PIL"):
        try:
            __import__(pkg)
        except ImportError:
            print(f"ERROR: missing package '{pkg}'. Install with:\n"
                  f"  pip install coremltools==8.0 torch onnx onnxsim onnx2torch Pillow")
            sys.exit(1)

    names = args.models if args.models else ["all"]
    if "all" in names or args.all:
        names = ["rtmpose", "insightface"]
    invalid = [n for n in names if n not in ("rtmpose", "insightface")]
    if invalid:
        parser.error(f"unknown model(s): {', '.join(invalid)} (choices: rtmpose, insightface, all)")

    results = {}
    for name in names:
        print(f"\n=== {name} ===")
        try:
            if name == "rtmpose":
                results[name] = convert_rtmpose(models_dir, not args.no_download) is not None
            elif name == "insightface":
                results[name] = convert_insightface(models_dir, not args.no_download) is not None
        except Exception as e:
            import traceback
            traceback.print_exc()
            results[name] = False

    print("\nSummary: " + ", ".join(f"{k}={'ok' if v else 'FAILED'}" for k, v in results.items()))
    sys.exit(0 if all(results.values()) else 1)


if __name__ == "__main__":
    main()
