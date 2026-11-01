# 引擎层设计

## 协议抽象

每个引擎实现一个协议，将命令层与推理后端解耦。这使得可以在不修改 CLI 命令的情况下替换模型。

### SegmentationEngine

```swift
protocol SegmentationEngine: Sendable {
    /// 从 `image` 中提取软掩码。白色 = 前景，黑色 = 背景，灰色 = 部分透明。
    func mask(for image: CGImage) throws -> SoftMask
    
    /// 可选的提示选择（点击位置 → 区域）。当前命令未使用，保留用于未来扩展。
    func mask(for image: CGImage, hint: SelectionHint) throws -> SoftMask?
}

struct SelectionHint: Sendable {
    let point: CGPoint      // 用户在此处点击
    let tolerance: Int      // 颜色接近度（用于魔棒式提示）
}

struct SoftMask: @unchecked Sendable {
    /// 图像分辨率的灰度覆盖率。0.0 = 完全透明，1.0 = 完全不透明。
    let pixels: [Float]     // 行优先排列，width * height 个元素
    let width: Int
    let height: Int
    
    /// 转换为 CGImage 用于输出或进一步处理。
    func asCGImage() -> CGImage { ... }
}
```

### InpaintingEngine

```swift
protocol InpaintingEngine: Sendable {
    /// 填充 `image` 中的掩码区域。掩码：1.0 = 填充，0.0 = 保留。
    func inpaint(_ image: CGImage, mask: SoftMask) throws -> CGImage
}

/// 以引擎配置形式暴露的算法特定预设。
enum InpaintingAlgorithm {
    case patchBased           // content_fill.c — 内置，零依赖（Phase 1）
    case lama(preset: LaMaPreset)   // MLX 推理 — 需要模型下载（Phase 2+）
}

struct LaMaPreset: Sendable {
    let internalResolution: Int   // 512 (快速), 1024 (均衡), 或 2048 (高质量)
    let iterations: Int           // 4, 8, 或 16
}
```

### GuidedRefinementEngine（可选抽象）

目前只有一个算法（引导滤波），暂不需要协议。`GuidedMatte.swift` 中的细化逻辑作为带静态方法的独立结构体保留：

```swift
nonisolated enum GuidedMatte {
    /// 使用引导图像边缘细化掩码。radius 控制范围，epsilon 控制边缘敏感度。
    static func filter(mask: [Float], guide: CGImage, width: Int, height: Int, radius: Int, epsilon: Float) -> [Float]
    
    /// 带默认参数的便利方法（匹配桌面应用行为）。
    static func refine(mask: CGImage, guide: CGImage, radius: Int = 3, limit: CGFloat = 0.5) throws -> CGImage
}
```

---

## 引擎实现

### VisionSegmentationEngine（内置）

封装 Apple 的 `VNGenerateForegroundInstanceMaskRequest`。无需下载。

```swift
nonisolated struct VisionSegmentationEngine: SegmentationEngine {
    func mask(for image: CGImage) throws -> SoftMask {
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        
        guard let result = request.results?.first, !result.allInstances.isEmpty else {
            throw SegmentationError.noSubjectDetected
        }
        
        let buffer = try result.generateScaledMaskForImage(
            forInstances: result.allInstances,
            from: handler
        )
        
        return SoftMask(cvPixelBuffer: buffer, width: image.width, height: image.height)
    }
}

enum SegmentationError: LocalizedError {
    case noSubjectDetected
    case visionFailure(reason: String)
}
```

**特性**：
- 速度：Apple Silicon（M 系列）上约 ~50–200ms
- 质量：对清晰的前景主体效果良好，复杂场景（多对象、遮挡）表现差
- 精度限制：超出 Vision 框架提供的范围无边缘细化能力

### SAM2SegmentationEngine（可选下载）

封装 Meta 的 Segment Anything Model 2（移动端变体）。需要 `~/Library/Application Support/Compositor/models/sam2-lightweight.mlx/`。

```swift
nonisolated struct SAM2SegmentationEngine: SegmentationEngine {
    let modelURL: URL
    
    init() throws {
        self.modelURL = try resolveModelKey("sam2-lightweight")
        guard FileManager.default.fileExists(atPath: modelURL.path) else {
            throw EngineError.modelMissing(key: "sam2-lightweight", downloadCommand: "compositor models download sam2-lightweight")
        }
    }
    
    func mask(for image: CGImage) throws -> SoftMask { ... }
}
```

**实现方式**：

1. 将 `CGImage` → MLX tensor（H, W, C；归一化到 [0, 1]）
2. 对整图运行 SAM2 encoder（不需要提示——使用全局分割的"全有"提示 token）
3. SAM2 decoder 产生每个对象的掩码；选择最大掩码作为前景
4. 后处理：转换为 `[Float]` SoftMask

**模型来源**：`facebookresearch/sam2` → 导出为 ONNX → 转换为 MLX safetensors 格式。"移动端"变体使用更轻量的图像编码器（EfficientNet-B4 backbone）和 3 层 decoder。

**近似规格**：
- 下载大小：~35MB 权重 + 配置
- 推理时间：Apple Silicon 上约 ~300–800ms
- 质量：显著优于 Vision，适用于复杂场景、部分遮挡、多主体

### LaMaInpaintingEngine（可选下载）

封装 LaMa 模型用于任意掩码修复。需要 `~/Library/Application Support/Compositor/models/lama-fast.mlx/`。

```swift
nonisolated struct LaMaInpaintingEngine: InpaintingEngine {
    let preset: LaMaPreset
    
    init(preset: LaMaPreset = .fast) {
        self.preset = preset
    }
    
    func inpaint(_ image: CGImage, mask: SoftMask) throws -> CGImage {
        // 1. 如有需要缩放到内部分辨率（保留宽高比并填充）
        // 2. 将图像 + 掩码转换为 MLX tensors
        // 3. 运行 LaMa 推理（编码器-解码器，含多尺度特征融合）
        // 4. 从填充区域裁剪回原分辨率
        // 5. 在边界处使用 alpha 合成混合以实现无缝过渡
    }
}

enum InpaintingError: LocalizedError {
    case modelMissing(key: String, downloadCommand: String)
    case dimensionMismatch(image: CGSize, mask: CGSize)
    case inferenceFailed(reason: String)
}
```

**实现方式**：

1. **预处理**：将图像 + 掩码填充到 `internalResolution` 正方形（例如 `fast` 预设的 512×512）。掩码以 0.5 为阈值二值化；软掩码保持原样用于 LaMa。
2. **推理**：加载预转换的 MLX 权重，运行前向传递。LaMa 使用两阶段方法：粗略补全 → 多尺度特征匹配细化。
3. **后处理**：从填充区域裁剪。使用高斯加权过渡区（宽度 = 8px）混合边界像素以避免可见接缝。

**模型来源**：GitHub 上的 `advimman/lama`。预训练权重来自 `courtiee/LaMa` → PyTorch `.pth` → 通过自定义脚本转换为 MLX safetensors。"fast" 预设使用 `restore_perceptual_metric_learning_with_global_receptacle_exemplars` checkpoint（~15MB）。

### PatchBasedInpaintingEngine（内置，Phase 1）

复用 CompositorCore Rendering 层中现有的 `content_fill.c` 实现——与桌面应用的内容感知填充相同的基于补丁的合成算法。无任何外部依赖。

```swift
nonisolated struct PatchBasedInpaintingEngine: InpaintingEngine {
    func inpaint(_ image: CGImage, mask: SoftMask) throws -> CGImage {
        // 直接复用 CompositorCore 的 content_fill.c —— 基于补丁的合成
        // 与桌面应用的内容感知填充使用相同算法。确定性，零依赖。
    }
}
```

**为什么可行**：现有代码库中的 `content_fill` C 函数已经可以从周围像素进行基于补丁的合成。虽然不是 SOTA，但它是确定性的且零依赖。仅在通过 `--algorithm lama` 显式请求时才会用 LaMa 替换它。

---

## 模型解析

模型定位在已知路径：

```swift
func resolveModelKey(_ key: String) throws -> URL {
    let supportDir = try FileManager.default.url(
        for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    ).appendingPathComponent("Compositor").appendingPathComponent("models")
    
    let modelURL = supportDir.appendingPathComponent(key).appendingPathExtension("mlx")
    
    if !FileManager.default.fileExists(atPath: modelURL.path) {
        // 如果 MLX 转换尚未可用，也检查 .onnx 变体
        let onnxURL = modelURL.deletingPathExtension().appendingPathExtension("onnx")
        if FileManager.default.fileExists(atPath: onnxURL.path) { return onnxURL }
        
        throw EngineError.modelMissing(key: key, downloadCommand: "compositor models download \(key)")
    }
    
    return modelURL
}
```

### 模型下载协议

`compositor models download <key>` 命令处理下载。实现细节：

1. 每个 key 的下载 URL 在清单中硬编码（无需远程配置服务）：
   ```swift
   enum ModelManifest {
       static let entries: [String: ModelInfo] = [
           "sam2-lightweight": ModelInfo(
               url: "https://github.com/user/sam2-mobile/releases/download/v1.0/sam2-lightweight.safetensors",
               sha256: "...", size: 36700160
           ),
           "lama-fast": ModelInfo(
               url: "https://github.com/advimman/lama/releases/download/v1.0/lama-fast.safetensors",
               sha256: "...", size: 15728640
           )
       ]
   }
   ```
2. 下载使用 `URLSession`，带进度报告（verbose 模式下输出到 stderr）
3. 下载完成后验证 SHA-256 哈希。如不匹配，删除并报告错误。
4. 将 config.json 与权重一起存储以保存推理参数。

---

## 线程安全说明

| 引擎 | 内部状态 | 并发访问 |
|------|---------|---------|
| `VisionSegmentationEngine` | 无（无状态） | 安全——无可变状态 |
| `SAM2SegmentationEngine` | 首次调用时加载模型到内存 | 在 init() 中加载模型；此后推理为只读 |
| `LaMaInpaintingEngine` | 同 SAM2 | 相同模式 |
| `PatchBasedInpaintingEngine` | 无（纯 C 函数） | 安全——C 函数无状态 |

**模型加载策略**：模型在 `init()` 中加载一次，并在 CLI 进程生命周期内保留在内存中。由于 CLI 进程在每个命令调用后退出，这意味着：

- 首次调用带可选模型的命令时支付加载成本
- 后续调用（在同一进程中）可复用——但由于 CLI 是每次调用的独立进程，真正的收益在于桌面应用（如果嵌入 CompositorCore + Engines）可以在多个命令间保持模型加载状态。

对于独立 CLI 场景，这不太重要。重要的是在模型缺失时快速失败，而不是尝试加载并在推理中途失败。
