#!/usr/bin/env python3
"""ComfyUI txt2img client.

Usage:
  ~/.venv-art/bin/python comfyui_generate.py --prompt-file p.txt --out out.png
  [--workflow zimage|qwen|flux] [--w 1024 --h 1536 --steps N --guid X --seed -1]

Configuration (NO secrets/URLs are hardcoded in this file):
- The ComfyUI base URL and API-key file path are read from
  ~/.codebuddy/assets/art-design/local_config.json (keys: "comfyui_base",
  "comfyui_key_path"), written by setup.sh. An env override COMFYUI_BASE is
  also honored. If unset, the script exits with a clear instruction to run
  setup.sh.
- The API key itself lives ONLY in the file named by comfyui_key_path (default
  ~/.codebuddy/assets/art-design/comfyui_1238.key), never in this source.

Server rules (verified on the deployment):
- Single GPU shared with a resident LLM: SERIAL calls only. A local flock
  prevents concurrent local invocations; agents must queue.
- POST /free (unload_models+free_memory) before submitting to avoid OOM on
  model switches.
- Errors appear in /history/{pid} status, not in /prompt response.
- Timings: zimage ~1-1.5 min, qwen distill ~6.5 min; budget 10 min per call.
- Fixed --seed reproducible; seed=-1 random per call.
"""
import argparse, fcntl, json, os, pathlib, re, sys, time, urllib.request

CONFIG_FILE = pathlib.Path.home() / ".codebuddy/assets/art-design/local_config.json"
DEFAULT_KEY_FILE = pathlib.Path.home() / ".codebuddy/assets/art-design/comfyui_1238.key"
LOCK_FILE = pathlib.Path.home() / ".codebuddy/assets/art-design/comfyui_1238.lock"
# (default steps, default cfg, approx seconds)
WF_DEFAULTS = {"zimage": (4, 2.5, 90), "qwen": (8, 1.0, 400), "flux": (20, 3.5, 300)}


def _config():
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text())
        except Exception:
            return {}
    return {}


def base():
    cfg = _config()
    url = cfg.get("comfyui_base") or os.environ.get("COMFYUI_BASE")
    if not url:
        raise SystemExit(
            "ComfyUI base URL is not configured. Run setup.sh (or set COMFYUI_BASE "
            "and comfyui_key_path in ~/.codebuddy/assets/art-design/local_config.json).")
    return url.rstrip("/")


def key_file():
    cfg = _config()
    p = cfg.get("comfyui_key_path") or str(DEFAULT_KEY_FILE)
    return pathlib.Path(p).expanduser()


def key():
    kf = key_file()
    if not kf.exists():
        raise SystemExit(f"ComfyUI API key file not found: {kf}. Run setup.sh.")
    return kf.read_text().strip()


def req(path, data=None, method=None, binary=False, timeout=60):
    r = urllib.request.Request(base() + path, data=data, method=method)
    r.add_header("X-API-Key", key())
    if data is not None:
        r.add_header("Content-Type", "application/json")
    with urllib.request.urlopen(r, timeout=timeout) as resp:
        body = resp.read()
    if binary:
        return body
    return json.loads(body) if body.strip() else {}


def acquire_lock():
    fh = open(LOCK_FILE, "w")
    try:
        fcntl.flock(fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        sys.exit("another ComfyUI task holds the lock (single-GPU server: run one task at a time)")
    return fh  # keep open; lock released on process exit


def free_memory():
    req("/free", json.dumps({"unload_models": True, "free_memory": True}).encode(), method="POST")
    print("freed server memory", flush=True)


def workflow(prompt, negative, wf, w, h, steps, guid, seed):
    clip_src = ["9", 0]
    if wf == "zimage":
        loader = {"1": {"class_type": "UNETLoader", "inputs": {"unet_name": "z_image_turbo_bf16.safetensors", "weight_dtype": "default"}},
                  "9": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_3_4b.safetensors", "type": "lumina2"}}}
        vae = "ae.safetensors"
    elif wf == "qwen":
        loader = {"1": {"class_type": "UNETLoader", "inputs": {"unet_name": "qwen_image_distill_full_fp8_e4m3fn.safetensors", "weight_dtype": "default"}},
                  "9": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_2.5_vl_7b_fp8_scaled.safetensors", "type": "qwen_image"}}}
        vae = "qwen_image_vae.safetensors"
    else:  # flux1-dev (3 shards auto-resolved by name prefix)
        loader = {"1": {"class_type": "UNETLoader", "inputs": {"unet_name": "flux1-dev.safetensors", "weight_dtype": "default"}},
                  "9": {"class_type": "DualCLIPLoader", "inputs": {"clip_name1": "clip_l.safetensors",
                                                                   "clip_name2": "t5xxl_fp8_e4m3fn.safetensors", "type": "flux"}}}
        vae = "flux1-dev-vae.safetensors"
    return {
        **loader,
        "2": {"class_type": "CLIPTextEncode", "inputs": {"text": prompt, "clip": clip_src}},
        "3": {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": clip_src}},
        "4": {"class_type": "EmptyLatentImage", "inputs": {"width": w, "height": h, "batch_size": 1}},
        "5": {"class_type": "KSampler", "inputs": {
            "model": ["1", 0], "positive": ["2", 0], "negative": ["3", 0], "latent_image": ["4", 0],
            "seed": seed, "steps": steps, "cfg": guid,
            "sampler_name": "euler", "scheduler": "simple", "denoise": 1.0}},
        "6": {"class_type": "VAELoader", "inputs": {"vae_name": vae}},
        "7": {"class_type": "VAEDecode", "inputs": {"samples": ["5", 0], "vae": ["6", 0]}},
        "8": {"class_type": "SaveImage", "inputs": {"images": ["7", 0], "filename_prefix": "codebuddy"}},
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--prompt-file", required=True)
    ap.add_argument("--negative", default="")
    ap.add_argument("--out", required=True)
    ap.add_argument("--workflow", choices=["zimage", "qwen", "flux"], default="zimage")
    ap.add_argument("--w", type=int, default=1024)
    ap.add_argument("--h", type=int, default=1536)
    ap.add_argument("--steps", type=int, default=None)
    ap.add_argument("--guid", type=float, default=None)
    ap.add_argument("--seed", type=int, default=-1)
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("--no-free", action="store_true", help="skip POST /free before submit")
    a = ap.parse_args()

    d_steps, d_guid, _ = WF_DEFAULTS[a.workflow]
    steps = a.steps if a.steps is not None else d_steps
    guid = a.guid if a.guid is not None else d_guid
    seed = a.seed if a.seed >= 0 else int(time.time()) % (2**32)

    lock = acquire_lock()

    prompt = pathlib.Path(a.prompt_file).read_text()
    prompt = re.sub(r"\n?\s*avoid:\s*", ", avoid: ", prompt).strip()
    if not a.negative and "avoid:" in prompt:
        a.negative = prompt.split("avoid:", 1)[1].strip()
        prompt = prompt.split("avoid:", 1)[0].strip()

    if not a.no_free:
        try:
            free_memory()
        except Exception as e:
            print(f"warn: /free failed ({e}), continuing", file=sys.stderr)

    pid = req("/prompt", json.dumps({"prompt": workflow(prompt, a.negative, a.workflow, a.w, a.h, steps, guid, seed)}).encode())["prompt_id"]
    print(f"prompt_id={pid} workflow={a.workflow} seed={seed} steps={steps} cfg={guid}", flush=True)

    t0 = time.time()
    while time.time() - t0 < a.timeout:
        time.sleep(5)
        try:
            h = req(f"/history/{pid}")
        except Exception:
            continue
        if pid not in h:
            continue
        entry = h[pid]
        status = entry.get("status", {})
        if status.get("status_str") == "error":
            msgs = status.get("messages", [])
            print("ERROR:", json.dumps(msgs, ensure_ascii=False)[:1500], file=sys.stderr)
            sys.exit(1)
        outputs = entry.get("outputs", {})
        imgs = [i for n in outputs.values() for i in n.get("images", [])]
        if imgs:
            img = imgs[0]
            data = req(f"/view?filename={img['filename']}&type={img.get('type','output')}&subfolder={img.get('subfolder','')}", binary=True, timeout=120)
            out = pathlib.Path(a.out)
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_bytes(data)
            print(f"saved: {out} ({len(data)} bytes, {time.time()-t0:.0f}s)", flush=True)
            meta = {"prompt_id": pid, "workflow": a.workflow, "seed": seed, "steps": steps,
                    "cfg": guid, "w": a.w, "h": a.h, "prompt": prompt, "negative": a.negative,
                    "server": base(), "elapsed_s": round(time.time() - t0)}
            out.with_suffix(".meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2))
            return
        if status.get("completed"):
            print("completed with no outputs", file=sys.stderr)
            sys.exit(1)
    print(f"timeout after {a.timeout}s", file=sys.stderr)
    sys.exit(1)


if __name__ == "__main__":
    main()
