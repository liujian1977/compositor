# Compositor CLI 架构设计

## 概述

Compositor CLI 是一个确定性的图像处理命令行接口，专为 LLM agent 调用而设计。它提供精确、可验证的操作，用于主体提取、图像修复、选区操作和图片导出——全部建立在现有 [Compositor](https://github.com/robbietilton/Compositor) 代码库之上。

**设计原则**：每个 CLI 命令都是一个纯函数 `f(输入, 参数) → 输出`。相同的输入 + 相同的参数总是产生相同的结果。没有歧义，没有主观判断。

## 状态 (v0.1.0)

| 组件 | 状态 |
|------|------|
| 分层架构 | ✅ 已实现 |
| 命令层（extract/inpaint/selection-modify/export/models） | ✅ 已实现 |
| 引擎层（Vision/SAM2 分割、基于 patch 的修复） | ✅ 已实现 |
| 核心层（C 像素操作、文档/IO 模块） | ✅ 已实现 |
| 模型下载引擎（ModelScope + HuggingFace） | ✅ 已实现 |
| Native ML 管线（Core ML 集成用于姿态/换脸） | ✅ 已实现 — Phase 2（推理需运行模型转换脚本） |
| 管线编排命令 | ✅ 已实现 — Phase 2 |

---

## 分层架构

```
┌──────────────────────────────────────────────────────┐
│                   LLM Agent                          │
│  (语义理解、意图推断、参数选择、结果评估)             │
└─────────────────────┬────────────────────────────────┘
                      │ 精确的 JSON/文本命令
                      ▼
┌──────────────────────────────────────────────────────┐
│                Compositor CLI                         │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │             命令层 ✅ v0.1.0                  │   │
│  │                                              │   │
│  │  extract │ inpaint │ selection-modify │ export│   │
│  │  models (list/download/remove)               │   │
│  └──────────────┬───────────────────────────────┘   │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐   │
│  │             引擎层 ✅ v0.1.0                  │   │
│  │                                              │   │
│  │  SegmentationEngine (Vision | SAM2)          │   │
│  │  InpaintingEngine (patch-based | LaMa stub)  │   │
│  │  SelectionOps (expand|contract|feather|snap) │   │
│  └──────────────┬───────────────────────────────┘   │
│                 │                                    │
│  ┌──────────────▼───────────────────────────────┐   │
│  │             核心层 ✅ v0.1.0                  │   │
│  │                                              │   │
│  │  Document/        ← EditorSession, Selection │   │
│  │  Rendering/       ← C 像素操作、无头渲染     │   │
│  │  IO/              ← 导入/导出                │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │        Native ML 管线 ✅ Phase 2             │   │
│  │                                              │   │
│  │  CoreML 模型加载器 (.mlpackage)              │   │
│  │  Vision Foundation (人脸检测、姿态估计)      │   │
│  │  Accelerate/vImage (预处理/混合)             │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │       管线编排器 ✅ Phase 2                   │   │
│  │                                              │   │
│  │  pipeline 命令（多步编排）                    │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

## 模块边界

### CompositorCore（新 Swift Package）✅ v0.1.0

从桌面应用中提取。仅包含确定性、无 UI 的逻辑：

| 模块 | 内容 | 依赖 | 状态 |
|------|------|------|------|
| `Document/` | Selection、Layer 模型、DocumentHistory、Crop、Guides、CanvasSize — 纯数据 + 逻辑。**EditorSession 保留在桌面应用中。** | 无（纯数据 + 逻辑） | ✅ 已实现 |
| `Rendering/` | C 像素操作 (`*.c`)，无头 Metal/CPU 渲染 | CompositorCore only | ✅ 已实现 |
| `IO/` | ImageImporter、ImageExporter、PSD 读写器、ProjectStore (.comp I/O) | Rendering | ✅ 已实现 |

**Core 规则**：
- 不允许 AppKit 或 SwiftUI 导入 — 由构建脚本强制执行
- 不允许 NSApplication、NSView、窗口管理、菜单命令、键盘快捷键
- 所有公开 API 必须是 `Sendable` 且确定性的（相同输入 → 相同输出）
- 不能依赖 CLI、Engine 或任何 ML 模型权重

### CompositorCLI（新可执行目标）✅ v0.1.0

CLI 入口点。围绕 Core 的薄封装：

| 包 | 职责 | 可导入 | 状态 |
|----|------|--------|------|
| `Commands/` | ArgumentParser 命令定义（`extract`、`inpaint`、`selection-modify`、`export`、`models`） | Core + Engines | ✅ 已实现 |
| `Engines/` | ML 推理协议 + 实现（VisionSegmentation、PatchInpainting） | Core | ✅ 已实现 |
| `Ops/` | 传统图像操作（Sobel、Canny） | Core | ✅ 已实现 |

**CLI 规则**：
- 每个命令必须可独立测试，无副作用
- 所有文件 I/O 发生在边界；内部操作在 CGImage/[UInt8] 上工作
- ML 模型是可选的：如果找不到模型，返回错误 — 不要回退到不同的模型

### 桌面应用（现有 Compositor.xcodeproj）

保持不变。继续使用所有现有的 SwiftUI/AppKit 代码。可以依赖 CompositorCore 实现共享逻辑，但对 CLI 包没有依赖关系。

## 数据流示例：`extract` 命令

```
用户/Agent 输入: --input photo.png --model vision --refine-radius 3 --format json
        │
        ▼
Commands/ExtractCommand.run()          [阶段: read_input, ~12ms]
        │ 读取文件 → CGImage
        │ 创建 ExtractParams { model: .vision, refineRadius: 3 }
        │
        ▼
Engines/VisionSegmentationEngine       [阶段: segmentation, ~180ms]
        │ VNGenerateForegroundInstanceMaskRequest → CVPixelBuffer → SoftMask
        │
        ▼ (如果 refineRadius > 0)
Core/GuidedMatte.filter                [阶段: refinement, ~35ms]
        │ box blur mean pass × 2，斜率/偏移计算，最终 clamp
        │ → 细化后的掩码 [Float] → CGImage（灰度 PNG）
        │
        ▼
Commands/ExportCommand.writePNG(mask, to: "mask.png")  [阶段: write_output, ~7ms]
```

## 数据流示例：`inpaint` 命令

```
用户/Agent 输入: --image photo.jpg --mask obj_mask.png --algorithm lama --lama-preset balanced
        │
        ▼
Commands/InpaintCommand.run()          [阶段: read_input, ~15ms]
        │ 读取图像 → CGImage，读取掩码 → SoftMask，验证维度匹配
        │
        ▼ (如果 algorithm == patch-based)
Core/PatchBasedInpaintingEngine        [阶段: inpainting, ~200ms]
        │ 复用 content_fill.c — 基于周围像素的 patch 合成
        │ → CGImage 结果
        │
        ▼ (如果 algorithm == lama)
Engines/LaMaInpaintingEngine           [阶段: inpainting, ~2000-8000ms]
        │ 1. 将图像+掩码填充到内部分辨率正方形（例如 balanced 为 1024×1024）
        │ 2. 转换为 MLX tensors，运行前向传播（编码器-解码器 + 多尺度融合）
        │ 3. 从填充区域裁剪，缩放到原始分辨率
        │ 4. 使用高斯权重过渡区混合边界（8px 宽度）
        │ → CGImage 结果
        │
        ▼
Commands/ExportCommand.writePNG(result, to: "result.png")  [阶段: write_output, ~10ms]
```

## 数据流示例：`selection-modify` 命令 (wand)

```
用户/Agent 输入: --input landscape.jpg --operation wand --point 400,120 --tolerance 64
        │
        ▼
Commands/SelectionModifyCommand.run()  [阶段: read_input, ~8ms]
        │ 读取图像 → CGImage，解析点 (400,120)
        │
        ▼
Core/MagicWand.select(in:at:settings:) [阶段: selection, ~50ms]
        │ 1. 将图像绘制到 CGContext raster
        │ 2. 在点处采样颜色，使用 sampleSize 平均
        │ 3. 泛洪填充容差内的连接像素（C 函数 wand_mask）
        │ 4. 追踪轮廓到 CGPath（wand_trace C 函数）
        │ → 二值掩码 [UInt8]（255 = 选中，0 = 未选中）
        │
        ▼
Commands/ExportCommand.writePNG(mask, to: "selection.png")  [阶段: write_output, ~5ms]
```

## 模型管理 ✅ v0.1.0

模型是可选的，首次使用时下载。

```
~/Library/Application Support/Compositor/models/
├── sam2-lightweight.mlx/          # ~156MB（可选，来自 ModelScope）
│   ├── model.safetensors
│   └── config.json
└── lama-fast.mlx/                 # ~195MB（可选，来自 HuggingFace）
    └── big-lama.safetensors
```

**规则**：
- 模型由字符串键标识：`"vision"`（内置）、`"sam2-lightweight"`、`"lama-fast"`
- 内置模型（Vision Framework）无需下载
- 可选模型在首次使用时触发交互式下载提示，或通过 `compositor models download <key>` 预先下载
- 模型文件在运行时不会被修改；权重只读

---

## Native ML 管线架构 ✅ Phase 2

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

---

## 线程和并发

| 操作 | 线程策略 |
|------|---------|
| C 像素操作 (`*.c`) | 已线程安全，从串行队列调用 |
| ML 推理（MLX） | MLX 内部并行；CLI 调用是顺序的 |
| 文件 I/O | 用于读/写操作的串行 DispatchQueue |
| 进度报告 | Async/await，仅在启用交互模式时使用 `@MainActor` |

---

## 错误处理策略

每个命令返回三种状态之一：

```swift
enum CommandResult {
    case success(url: URL)        // 输出写入此路径
    case failure(CommandError)     // 用于 agent 处理的类型化错误
}

enum CommandError: LocalizedError {
    case fileNotFound(path: String)
    case invalidImageFormat(url: URL)
    case modelMissing(key: String, downloadCommand: String)
    case inferenceFailed(reason: String)
    case renderFailed(reason: String)
}
```

**无静默失败**。每个错误都包含机器可读的原因和可选的恢复提示（例如缺失模型的下载命令）。LLM agent 可以解析 `--format json` 输出以做出决策。

---

## Phase 2 实施计划 ✅（已完成）

### 范围

添加 Native ML Pipeline 命令 + 管线编排器：
- `face-detect`：Vision Foundation 人脸检测（内置，无需下载模型）
- `pose-estimate`：Core RTMPose 身体关键点模型（需要一次性 Python → CoreML 转换）
- `face-swap`：InsightFace 面部替换（需要一次性 Python → CoreML 转换）
- `composite`：Alpha 混合 + Poisson 融合，通过 CoreC 像素操作
- `pipeline`：多步编排命令

### 实际交付的文件（与计划文件名略有出入）

| 文件 | 操作 | 描述 |
|------|------|------|
| `CompositorCLI/PipelineRunner.swift` | **新建** | 编排引擎 — 每步计时的顺序步骤执行（放在 CLI 目标内，因为需要调用各命令 Runner；计划中原写作 CompositorCore） |
| `CompositorCore/CoreDocument/ModelLoader.swift` | **新建** | Core ML 模型加载器，从 `.mlpackage` 目录 |
| `CompositorCLI/FaceDetectCommandRunner.swift` | **新建** | VNDetectFaceRectanglesRequest 封装（含置信度过滤与坐标翻转） |
| `CompositorCLI/PoseEstimateCommandRunner.swift` | **新建** | RTMPose CoreML 推理 + JSON 输出 |
| `CompositorCLI/FaceSwapCommandRunner.swift` | **新建** | InsightFace CoreML 推理 + 羽化混合 |
| `CompositorCLI/CompositeCommandRunner.swift` | **新建** | composite 命令（alpha/difference/poisson） |
| `CompositorCore/CoreRendering/CompositeOp.c/.h/.swift` | **新建** | Alpha 混合、difference、Poisson 融合（迭代梯度域求解） |
| `tools/convert_models.py` | **新建** | Python 一次性模型转换脚本 |
| `Package.swift` | 编辑 | CoreML framework 添加到 CompositorCLI 目标链接器设置 |

### 实施状态

1. **Phase 2.0**：✅ Package.swift CoreML framework；ModelLoader.swift
2. **Phase 2.1**：✅ FaceDetectCommandRunner（Vision API，零依赖）
3. **Phase 2.2**：✅ Python 模型转换脚本（`tools/convert_models.py`）用于 RTMPose + InsightFace
4. **Phase 2.3**：✅ PoseEstimateCommandRunner + FaceSwapCommandRunner — CoreML 推理封装
5. **Phase 2.4**：✅ CompositeOp（CoreC）+ CompositeCommandRunner
6. **Phase 2.5**：✅ PipelineRunner — 带每步 JSON 输出的编排层（支持 `--pipeline-config` 与 `${step.output}` 变量引用）
7. **Phase 2.6**：⏳ 待模型转换后做完整管线集成测试；M2 Pro 性能基准测试

### 测试策略

- 每个新命令都有自己独立的 `*IntegrationTests.swift` 文件（匹配现有模式）
- 管线测试创建临时中间文件并验证每步的输出
- 性能测试测量每步计时以验证 CoreML 加速效果
