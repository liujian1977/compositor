# Compositor CLI 命令规范

## 全局选项

```bash
compositor <command> [options] [--output <path>] [--format json] [--version] [--help]
```

| 标志 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `--format` | `text\|json` | `text` | 输出格式。`json` 返回结构化结果供 agent 解析（包含计时数据） |
| `--verbose` | 标志 | off | 将进度打印到 stderr（不影响 stdout）。不改变 stdout 内容。 |

> **注意**：`--output <path>` 仅由产生输出的命令使用（`extract`、`inpaint`、`selection-modify`、`export`）。`models` 命令不使用它。

---

## 已实现命令 (v0.1.0)

---

### 命令：extract ✅ (v0.1.0)

使用语义分割从图像中提取主体，输出软掩码。

```bash
compositor extract \
    --input <image.png> \
    [--model vision|sam2-lightweight] \
    [--refine-radius 0..20] \
    [--contrast-threshold 0.0..1.0] \
    [--edge-shift -10..10] \
    --output <mask.png>
```

#### 参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| `--input` | URL 路径 | 是 | — | 源图像（JPEG、PNG） |
| `--model` | 枚举 | 否 | `vision` | 分割模型。`"vision"` = Apple Vision Framework 启发式（内置）。`"sam2-lightweight"` = SAM2（首次使用时 ~35MB 下载） |
| `--refine-radius` | int | 否 | `0` | Guided Filter 半径，单位为像素。范围 1–20。值为 `0` 则跳过细化 |
| `--contrast-threshold` | float | 否 | `0.75` | 推开掩码灰度值。`0.0` = 无变化，`1.0` = 在中灰色处硬切割。仅在 refine-radius > 0 时有效 |
| `--edge-shift` | int | 否 | `0` | 向内（负数）或向外（正数）移动边缘。典型值：`-2` 以去除背景颜色光晕 |

#### 输出

- **stdout**（text 模式）：成功时输出 `OK mask.png`，失败时输出错误消息
- **stdout**（json 模式）：`{ "status": "success", "output": "/path/to/mask.png" }`

#### 错误情况

| 条件 | 退出码 | JSON 错误 |
|------|--------|-----------|
| `--input` 文件未找到 | 1 | `{ "error": { "type": "fileNotFound", "detail": "...", "hint": null } }` |
| 模型键为 `"sam2-lightweight"` 但模型未下载 | 1 | `{ "error": { "type": "modelMissing", "detail": "sam2-lightweight", "hint": "compositor models download sam2-lightweight" } }` |
| 图像解码后维度为零 | 1 | `{ "error": { "type": "invalidImageFormat", "detail": "...", "hint": null } }` |

#### 使用示例

```bash
# 简单主体提取（快速，内置）
compositor extract --input portrait.jpg --output mask.png

# 高精度 + SAM2 + 边缘细化
compositor extract --input photo.png \
    --model sam2-lightweight \
    --refine-radius 5 \
    --contrast-threshold 0.8 \
    --edge-shift -1 \
    --output mask.png --format json
```

---

### 命令：inpaint ✅ (v0.1.0)

使用内容感知合成填充掩码区域。

```bash
compositor inpaint \
    --image <photo.png> \
    --mask <selection.png> \
    [--algorithm patch-based|lama] \
    [--la-ma-preset fast|balanced|high] \
    --output <result.png>
```

#### 参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| `--image` | URL 路径 | 是 | — | 要修复的源图像 |
| `--mask` | URL 路径 | 是 | — | 二值/软掩码。白色 = 填充区域，黑色 = 保留。灰度 = 部分填充 |
| `--algorithm` | 枚举 | 否 | `patch-based` | 修复算法。默认为基于 patch（C 实现）。LaMa 需要下载模型（Phase 2）。见下表了解所有选项。 |
| `--la-ma-preset` | 枚举 | 否 | `balanced` | LaMa 质量等级。仅在 `--algorithm lama` 时有效。影响内部模型分辨率和迭代次数。默认为 balanced。 |

#### 算法对比

| 算法 | 需要模型 | 速度 | 质量 | 引入阶段 |
|------|---------|------|------|---------|
| `patch-based` | 无（内置） | 快速（~200ms） | 中等 | v0.1.0 — CoreC/PatchInpaintOp.c 中的 C 实现。适用于小面积均匀区域、划痕 |
| `lama` | ~195MB 下载 | 慢（M2 Pro 上约 ~4–8s） | SOTA | Phase 2 (stub) — LaMa 通过 MLX 推理。适用于任意掩码尺寸、复杂背景、大对象 |

> **注意**：LaMa 在 v0.1.0 中实现为模型检查 + stub。实际的 MLX 推理后端将在 Core ML 集成完成后的 Phase 2 添加。

#### 输出

与 `extract` 相同格式。

#### 错误情况

| 条件 | 退出码 | JSON 错误类型 |
|------|--------|---------------|
| `--mask` 与 `--image` 维度不匹配 | 1 | `"dimensionMismatch"` |
| 指定 `--algorithm lama` 但 LaMa 模型未找到 | 1 | `"modelMissing"`，提示：下载命令 |
| `--input` 文件未找到 | 1 | `"fileNotFound"` |

#### 使用示例

```bash
# 小划痕修复，内置 patch-based 算法 (v0.1.0)
compositor inpaint --image damaged.jpg \
    --mask scratch.png \
    --algorithm patch-based \
    --output fixed.png

# 大区域填充使用 LaMa（Phase 2 - v0.1.0 中为 stub，v1.x 中完整实现）
compositor inpaint --image scene.jpg \
    --mask unwanted_object.png \
    --algorithm lama \
    --la-ma-preset balanced \
    --output cleaned.png --format json
```

---

### 命令：selection-modify ✅ (v0.1.0)

操作二值/软选区掩码。所有操作都是确定性的且可参数化。

#### 子操作

##### 1. expand / contract（几何操作）

```bash
compositor selection-modify \
    --input <mask.png> \
    --operation expand|contract \
    --amount <number> \
    [--unit pixels|percent] \
    --output <result.png>
```

- `expand`：将掩码膨胀 N 像素（或图像宽度的百分比）
- `contract`：将掩码腐蚀 N 像素
- 两者都使用 8-连接邻域，无亚像素插值

##### 2. feather（边缘高斯模糊）

```bash
compositor selection-modify \
    --input <mask.png> \
    --operation feather \
    --amount <number> \
    [--unit pixels|percent] \
    --output <result.png>
```

- 对掩码 alpha 通道应用高斯模糊，σ = amount
- 将输出限制在 [0, 1] 范围

##### 3. edge-snap（Sobel 引导对齐）

```bash
compositor selection-modify \
    --input <mask.png> \
    --operation edge-snap \
    --guide <image.png> \       # 可选：如果省略，则使用掩码自身的灰度值
    [--sobel-threshold 0.1..1.0] \
    [--snap-radius 5] \
    --output <result.png>
```

- 在 `--guide` 图像（或 `--input` 的灰度值）上计算 Sobel 边缘图
- 对于掩码中的每个边界像素，在 `--snap-radius` 范围内搜索最近的最高梯度位置
- 阈值确定什么算作"高梯度"（归一化 0–1）

##### 4. wand（基于颜色的选区）

```bash
compositor selection-modify \
    --input <image.png> \
    --operation wand \
    --point x,y \               # 像素中的点击位置，左上角原点
    --tolerance 0..255 \        # 每通道颜色差异阈值
    [--sample-size point|3x3|5x5] \
    [--contiguous true|false] \
    --output <selection.png>
```

- 与桌面应用的魔棒工具相同的算法：基于颜色相似度的泛洪填充
- 完全确定性的，无 ML 组件
- `--point` 为图像像素坐标（0-based）

#### 参数（所有操作的公共参数）

| 参数 | 类型 | 必填 | 描述 |
|------|------|------|------|
| `--input` | URL 路径 | 是 | expand/contract/feather/edge-snap 的源**掩码**。wand 操作的源**图像**。 |
| `--operation` | 枚举 | 是 | 其中之一：expand、contract、feather、edge-snap、wand |
| `--amount` / `--point` / 等 |  varies | 是 | 操作特定参数（见各子节） |
| `--guide` | URL 路径 | 条件性 | edge-snap 时，当输入不是具有可用亮度的图像时为必需 |

#### 输出

与其他命令相同格式。对于 `wand`，输出的掩码在选中区域为 255，其余为 0。

#### 使用示例

```bash
# 将选区扩展 10 像素
compositor selection-modify --input region.png \
    --operation expand --amount 10 --unit pixels \
    --output expanded.png

# 掩码边缘羽化（平滑过渡）
compositor selection-modify --input hard_mask.png \
    --operation feather --amount 3 --unit pixels \
    --output soft_mask.png

# 魔棒：通过颜色选择天空区域
compositor selection-modify --input landscape.jpg \
    --operation wand --point 400,120 --tolerance 64 \
    --contiguous true --output sky_sel.png
```

---

### 命令：export ✅ (v0.1.0)

从项目或原始图像文件中导出合成图像。

```bash
compositor export \
    --input <image.png|project.comp> \
    [--format png|jpeg|pdf] \
    [--quality 1..100] \       # JPEG 质量，PNG/PDF 时忽略
    [--scale 0.01..4.0] \      # 缩放因子（1.0 = 原始大小）
    --output <result.ext>
```

#### 参数

| 参数 | 类型 | 必填 | 默认值 | 描述 |
|------|------|------|--------|------|
| `--input` | URL 路径 | 是 | — | 源图像或 Compositor 项目文件夹（.comp） |
| `--format` | 枚举 | 否 | 从输出扩展名推断 | 输出格式。PNG（无损）、JPEG（有损） |
| `--quality` | int 1–100 | 条件性 | 92 | JPEG 质量因子。仅在 format 为 jpeg 时有效 |
| `--scale` | float | 否 | 1.0 | 输出缩放因子。`0.5` = 半分辨率，`2.0` = 双倍（>1.0 时使用最近邻） |

#### 输出

与其他命令相同格式。

---

### 命令：models ✅ (v0.1.0)

管理可选 ML 模型下载。

```bash
# 列出可用和已安装的模型
compositor models list [--json]

# 下载模型
compositor models download <key> [--force]

# 删除已下载的模型
compositor models remove <key>
```

#### 可用模型

| 键 | 大小 | 描述 | 被谁使用 | 来源 |
|----|------|------|---------|------|
| `sam2-lightweight` | ~156MB | SAM2 Hiera-Tiny 分割模型 | `extract --model sam2-lightweight` | ModelScope (AI-ModelScope/sam2-hiera-tiny) |
| `lama-fast` | ~195MB | LaMa 修复 big 模型 | `inpaint --algorithm lama` | HuggingFace (AEmotionStudio/lama-inpainting) |

> **注意**：v0.1.0 中的大小反映实际模型文件：SAM2 safetensors（~156MB）、LaMa safetensors（~195MB）。之前的规范列出了轻量级变体的较小大小，但这些在下载源中尚不可用。

#### 输出 (list)

```json
[
  {"key": "vision", "status": "built-in", "size_mb": 0},
  {"key": "sam2-lightweight", "status": "installed|missing", "size_mb": 156},
  {"key": "lama-fast", "status": "installed|missing", "size_mb": 195}
]
```

---

## Phase 2 命令（Native ML 管线）

### 命令：face-detect ✅（已实现 — Phase 2）

使用 Vision Foundation API 检测图像中的人脸，输出边界框。

```bash
compositor face-detect \
    --input <image.png> \
    [--min-confidence 0.5] \
    --output <faces.json>
```

- 使用 Vision Framework 的 `VNDetectFaceRectanglesRequest`（内置，无需下载模型）
- 输出：每个检测到的脸部的 `{x, y, width, height, confidence}` JSON 数组（左上角原点坐标）
- **状态**：已实现。`FaceDetectCommandRunner.swift`，Vision API 在 macOS 14+ 上可用。

### 命令：pose-estimate ✅（命令已实现 — 需模型转换）

使用 Core ML 模型估计人体关键点。

```bash
compositor pose \
    --input <image.png> \
    [--model rtmpose|dwpose] \
    --output <poses.json>
```

- **模型**：RTMPose 或 DWPose，通过 `coremltools` 转换为 Core ML（Python 一次性转换）
- 输出：每个关节点的 `{x, y, confidence}` JSON 数组（例如 DWPose 为 133 个点）
- **状态**：命令与 CoreML 推理已实现（`PoseEstimateCommandRunner.swift`）。模型未转换时返回 `modelMissing` 错误并给出转换提示。详见下方的 Native ML Pipeline 部分。

### 命令：face-swap ✅（命令已实现 — 需模型转换）

将一张图像中的人脸替换为另一张图像中的人脸。

```bash
compositor face-swap \
    --source <source_face.jpg> \
    --target <target_image.jpg> \
    [--model insightface] \
    --output <result.png>
```

- **模型**：InsightFace / SimSwap，通过 `coremltools` 转换为 Core ML
- 管线：人脸检测（Vision）→ 裁剪 → CoreML 推理 → 羽化混合回原图
- **状态**：命令与推理/混合已实现（`FaceSwapCommandRunner.swift`）。模型未转换时返回 `modelMissing` 错误并给出转换提示。详见下方的 Native ML Pipeline 部分。

### 命令：composite ✅（已实现 — Phase 2）

将多张图像组合在一起，支持各种混合模式。

```bash
compositor composite \
    --foreground <fg.png> \
    --background <bg.png> \
    [--mask <alpha_mask.png>] \
    [--blend-mode alpha|difference|poisson] \
    --output <result.png>
```

- Alpha 混合 / difference 混合 / Poisson 融合（梯度域，迭代求解）均由 CoreC `CompositeOp.c` 实现
- `--mask` 省略时使用前景图像自身的 alpha 通道；前景与背景尺寸必须一致
- **状态**：已实现。`CompositeCommandRunner.swift` + `CompositeOp.c/.h`。

### 命令：pipeline ✅（已实现 — Phase 2 编排层）

将多个子命令作为单个确定性管线进行编排，输出包含每步计时和中间结果的 JSON。

```bash
compositor pipeline \
    --input <source_image.jpg> \
    [--reference <reference_face.jpg>] \
    --steps extract,detect-poses,face-swap,inpaint \
    [--pipeline-config config.json] \
    --output <result.png> \
    --format json
```

#### 管线步骤参考

| 步骤名 | 映射到命令 | 必填输入 | 输出中间文件？ |
|--------|-----------|---------|--------------|
| `extract` | `compositor extract` | `--input`（源图像） | 是 — mask.png |
| `detect-faces` | `compositor face-detect` | `--input`（源图像） | 是 — faces.json |
| `detect-poses` | `compositor pose` | `--input`（源图像） | 是 — poses.json |
| `face-swap` | `compositor face-swap` | `--source`（来自 reference）、`--target`（来自 source 通过 detect-faces） | 否 — 就地修改或写入新文件 |
| `inpaint` | `compositor inpaint` | `--image`（源图像）、`--mask`（来自 extract） | 是 — inpainted.png |
| `composite` | `compositor composite` | `--foreground`、`--background`、`--mask` | 否 — 写入最终结果 |

#### 管线 JSON 输出

```json
{
    "command": "pipeline",
    "version": "0.1.0",
    "status": "success|error",
    "output": "/path/to/final_result.png",
    "steps": [
        {
            "name": "extract",
            "status": "success",
            "outputs": {
                "mask": "/tmp/intermediate-mask.png"
            },
            "timing_ms": 185,
            "error": null
        }
    ],
    "total_ms": 2400
}
```

- 每步记录自己的计时、输出（中间文件路径）和任何错误
- 如果某步失败，后续步骤被跳过；管线状态 = `"error"`
- 中间文件存储在 `$TMPDIR/compositor-pipeline-{UUID}/`，成功后清理
- 成功时最终中间结果会拷贝到 `--output` 指定的路径；`--pipeline-config` 接受 JSON 数组形式的步骤定义（可含每步 `parameters`）
- **状态**：已实现。`PipelineRunner.swift`（CLI 目标内），支持 extract / detect-faces / detect-poses / face-swap / inpaint / composite / selection-modify。

---

## JSON 输出模式（所有命令）

传递 `--format json` 时：

```json
{
    "command": "extract|inpaint|selection-modify|export|models|pipeline",
    "version": "0.1.0",
    "status": "success|error",
    "output": "/absolute/path/to/output.png",   // status == success 时存在，error 时为 null
    "error": {                                  // status == error 时存在
        "type": "fileNotFound|modelMissing|invalidImageFormat|dimensionMismatch|inferenceFailed|renderFailed",
        "detail": "人类可读的描述",
        "hint": "恢复建议或 null"
    },
    "timing": {                                 // 始终存在，用于调试和 agent 重试逻辑
        "total_ms": 1234,
        "phases": [
            { "name": "read_input", "ms": 12 },
            { "name": "segmentation|inpainting|selection", "ms": 456 },
            { "name": "refinement", "ms": 89 }   // 仅在应用细化时存在
        ]
    }
}
```

成功时退出码为 `0`，错误时为 `1`。退出码 `2` 表示内部 panic（不应发生 — 如果遇到请提交 bug）。

### 按命令的相位名称

| 命令 | `timing.phases[].name` 中的可能相位名 |
|------|---------------------------------------|
| `extract` | `read_input`、`segmentation`、`refinement`、`write_output` |
| `inpaint` | `read_input`、`inpainting`、`write_output` |
| `selection-modify` | `read_input`、`selection`、`write_output`（或 edge-snap 的 `sobel_compute` + `snap`） |
| `export` | `read_input`、`render`、`write_output` |
| `models list/download/remove` | `read_manifest`、`download`、`verify_hash`、`complete` |
| `pipeline` | `orchestrate`，加上每步自己的相位（见各步骤） |

---

## Native ML Pipeline 架构 (Phase 2+)

### 概述

对于基于 ML 的命令（`pose-estimate`、`face-swap`、`face-detect`），架构遵循两阶段模型工作流：

```
Python（一次性转换）：
  PyTorch / ONNX → coremltools → .mlpackage 文件

Swift CLI（运行时推理）：
  读取图像 → 预处理 → Core ML 推理 → 后处理 → 写入输出
```

**为什么这样拆分**：将 PyTorch/ONNX 模型转换为 Core ML 需要 `coremltools` 等 Python 工具。这是在安装时**一次性**完成的，不是在运行时。转换后，Swift CLI 完全使用原生框架 — 无需 Python 依赖。

### 模型转换（Python，一次性）

```bash
# tools/convert_models.py — 将 ONNX 模型转换为 Core ML 格式
# 依赖：Python 3.11 + coremltools 8.x + torch + onnx + onnxsim + onnx2torch + Pillow
# （coremltools ≥8 移除了 ONNX 前端，走 onnxsim→onnx2torch→TorchScript→ct.convert 路线）
python3 tools/convert_models.py --all
```

生成 `.mlpackage` 文件存储在：
```
~/Library/Application Support/Compositor/models-ml/
├── pose-rtmpose.mlpackage                # RTMPose-m 192×256，SimCC 输出（FP16）
├── face-swap-insightface.mlpackage       # inswapper_128（FP32，target 1/255 + source 512维）
├── face-recognition-insightface.mlpackage # ArcFace w600k_r50 embedding（FP16）
├── models-ml-manifest.json               # 转换元数据
└── .compiled/                            # Swift 运行时缓存（MLModel.compileModel）
```

模型来源：RTMPose 取自 ModelScope `AXERA-TECH/RTMPose`（rtmpose_m_256x192.onnx）；
inswapper_128 取自 GitHub deepinsight/insightface release v0.7；w600k_r50 取自
HuggingFace `public-data/insightface` buffalo_l。归一化（RTMPose ImageNet mean/std、
ArcFace ±127.5、inswapper /255）烘焙进模型，Swift 侧直接喂原始像素。
人脸检测本身通过 Vision API 内置（无需转换模型）。

### Swift 原生推理栈

| 框架 | 用途 | 示例用法 |
|------|------|---------|
| `CoreML` | 加载 `.mlpackage`，在 CPU/GPU/Neural Engine 上运行推理 | `PoseModel(configuration: config).prediction(input:)` |
| `Vision` | 人脸检测、人体分割（内置） | `VNDetectFaceRectanglesRequest` |
| `CoreImage / Accelerate / vImage` | 图像预处理、颜色空间转换、混合 | 调整大小、归一化像素缓冲区以适配模型输入 |
| `Foundation` | JSON I/O、文件管理、进度报告 | 读取/写入中间管线输出 |

### M2 Pro 16GB 性能预估（Phase 2+）

| 操作 | 预估时间 | 备注 |
|------|---------|------|
| Vision 人脸检测 | <100ms | 内置框架，零开销 |
| Core ML 姿态估计（RTMPose） | ~15ms 推理（实测） | 192×256 输入 + 首次加载 ~1s（编译缓存后更快） |
| Core ML 换脸（InsightFace） | ~1.1s 推理（实测，embedding 0.4s + swap 1.1s） | 128×128 输入，FP32 |
| vImage composite / blend | <50ms | Accelerate framework GPU 加速 |
| **完整管线**（extract→pose-detect→face-swap） | **~3–4s** | 顺序步骤，每个使用原生 Metal/ANE 加速 |

> **注意**：这些是 Phase 2 的预估。实际性能取决于模型量化（推荐 FP16）、输入分辨率以及特定模型架构是否可用 Neural Engine。
