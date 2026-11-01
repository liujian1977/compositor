# CompositorCore 公开 API 参考

本文件定义了 `CompositorCLI` 所依赖的确切函数签名、数据类型和格式契约。它是实现的唯一真实来源——如果与其他规范文档冲突，以本文档为准（相应更新命令/路线图文档）。

---

## 1. CompositorCore 模块结构

```
CompositorCore/
├── CoreDocument/          ← 纯数据模型 (Swift)
│   ├── Selection.swift    ← DocumentSelection, DocumentSelectionClip
│   └── CanvasSize.swift   ← width/height 值类型
├── CoreRendering/         ← C 像素操作 + Swift 包装器 (Swift + C)
│   ├── *.c / *.h          ← 现有 Compositor Rendering/*.c 文件
│   ├── MorphologyOp.c     ← 新增：expand/contract 膨胀/腐蚀
│   └── SobelOp.c          ← 新增：边缘检测
├── CoreIO/                ← 文件 I/O (Swift，无 AppKit)
│   ├── ImageExporter.swift
│   └── ProjectManifest.swift ← .comp 清单读写
```

---

## 2. SoftMask 类型 — 核心数据结构

所有引擎生产/消费 `SoftMask`。这是 ML 推理与 Core 渲染之间的桥梁。

### Swift 定义

```swift
/// 灰度覆盖率图：0.0 = 完全透明（背景），1.0 = 完全不透明（主体）。
/// 存储为 width * height 个元素的行优先 [Float] 数组。
struct SoftMask: Sendable {
    let pixels: [Float]     // 行优先，width * height 个元素，值钳位到 [0.0, 1.0]
    let width: Int
    let height: Int

    /// 转换为灰度 PNG 图像（每像素 8-bit）。白色 = 1.0，黑色 = 0.0。
    func asCGImage() throws -> CGImage

    /// 从 CVPixelBuffer 创建（Vision Framework 输出格式）。
    init(cvPixelBuffer buffer: CVPixelBuffer, width: Int, height: Int) throws

    /// 从 MLX tensor 输入创建 (H, W; 值假设在 [0.0, 1.0] 范围内)。
    init(mlxTensor: MLXArray)   // 需要 mlx-swift 包
}
```

### 类型转换链

每个引擎产生不同的原始格式。以下是转换为 `SoftMask` 的方式：

| 引擎 | 原始输出格式 | 到 SoftMask 的转换 |
|------|-------------|-------------------|
| Vision Framework | `VNGenerateForegroundInstanceMaskRequest` 输出的 `CVPixelBuffer`，8-bit 灰度，值在 [0, 255] | 将像素缓冲区读取为 UInt8 数组 → 每个值除以 255.0 → Float 数组钳位到 [0, 1] |
| SAM2 (MLX) | decoder 输出的 MLX tensor `[Float32](H, W)`，sigmoid 激活已应用 | 值已在 [0, 1] 范围内；直接按行优先布局复制到 pixels 数组 |
| GuidedMatte filter | `GuidedMatte.filter(mask:guide:radius:epsilon:)` 输出的 `[Float]` — 已通过 `min(1, max(0, ...))` 钳位 | 直接使用，无需转换 |

### SoftMask ↔ CGImage 转换 (asCGImage)

```swift
func asCGImage() throws -> CGImage {
    let width = self.width, height = self.height
    guard pixels.count == width * height else { throw CoreError.invalidData }

    // 创建灰度 CGContext
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) ?? throw CoreError.render

    // 将 [Float] → [UInt8]，直接写入 context 缓冲区
    let data = context.data!.bindMemory(to: UInt8.self, capacity: width * height)
    for i in 0..<pixels.count {
        data[i] = UInt8(round(min(1.0, max(0.0, pixels[i])) * 255))
    }

    // 从 context 创建 CGImage — 这会从 CGContext 复制数据
    guard let image = context.makeImage() else { throw CoreError.render }
    return image
}
```

**关键细节**：`asCGImage()` 通过 `context.makeImage()` 复制像素数据。生成的 `CGImage` 独立于 `SoftMask.pixels` 数组，可安全写入磁盘。

### SoftMask 的 C API（引擎使用）

```c
// 将 [Float] 像素转换为 CGImage 兼容格式（灰度，8-bit）。
// 调用者完成时必须 free(result)。成功返回 0，分配失败返回 -1。
int softmask_to_png(const float *pixels, size_t width, size_t height,
                    uint8_t **output_png_data, size_t *output_size);

// 将 CGImage 写入 PNG 文件（基于 CoreGraphics）。
// 成功返回 0，I/O 错误返回 -1。
int write_png(CGImageRef image, const char *path);
```

---

## 3. CoreRendering C API — 精确签名

以下所有函数都在 `CompositorCore/CoreRendering/` 中。它们操作原始像素缓冲区且完全确定性。无 Objective-C，无 Swift 依赖。

### 3.1 WandPixels（来自现有 Compositor 仓库）

已原样存在。CLI 包装器直接调用：

```c
// 魔棒泛洪填充选区。
// rgba: 预乘 RGBA 输入图像（每像素 4 字节，每行 stride 字节）。
// seedX/seedY: 点击位置（0-based，左上角原点）。
// radius: 颜色平均窗口 (2*radius+1)² — 对应 WandSampleSize。
// tolerance: 每通道最大差异（0–255）。
// contiguous: 1 = 仅从种子泛洪填充；0 = 图像中所有匹配像素。
// mask: 输出缓冲区，width * height 字节，写入 255（选中）或 0（未选中）。
// 返回：选中的像素数，OOM 时 -1，种子越界时 0。
long wand_mask(const uint8_t *rgba, size_t width, size_t height, size_t stride,
               size_t seedX, size_t seedY, size_t radius, int tolerance, int contiguous, uint8_t *mask);

// 追踪选区边界到 CGPath 就绪的角点。
// mask: wand_mask 输出的二进制 255/0 掩码。
// points: malloc'd int32_t 对数组 (x, y)，像素边缘坐标。
// loops: malloc'd 循环长度数组；每个循环是闭合轮廓。
// 返回：0 = 成功，-1 = OOM，-2 = 轮廓过于详细（>8M 条边）。
int wand_trace(const uint8_t *mask, size_t width, size_t height,
               int32_t **points, size_t *pointCount, int32_t **loops, size_t *loopCount);
```

**CLI Swift 包装器签名：**

```swift
// 在点击位置按颜色相似度选择像素。
// 返回二进制掩码 [UInt8]，其中 255 = 选中，0 = 未选中。
enum MagicWand {
    static func selectBinaryMask(
        in rgba: UnsafePointer<UInt8>,       // 图像数据（预乘 RGBA）
        width: Int, height: Int, stride: Int,
        point: CGPoint,                      // 点击位置
        tolerance: Int,                      // 0–255 每通道差异
        sampleSizeRadius: Int,               // 0=点，1=3x3，2=5x5
        contiguous: Bool                     // 连通泛洪填充 vs 全局匹配
    ) throws -> [UInt8]                    // width * height 字节，调用者必须释放
}
```

### 3.2 ContentFill（来自现有 Compositor 仓库）— Inpainting 引擎

已原样存在：

```c
// 基于补丁的内容感知填充。
// pixels: RGBA 图像数据原地修改；mask 定义要填充的区域。
// mask: 灰度掩码，其中 >0 表示"填充此像素"。
// 返回：1 = 成功，0 = 无源补丁可用（所有像素都被掩码），-1 = OOM。
int content_fill(uint8_t *pixels, size_t stride, const uint8_t *mask, size_t maskStride, int width, int height);
```

**CLI Swift 包装器签名：**

```swift
enum PatchBasedInpainting {
    /// 使用来自周围像素的基于补丁的合成填充掩码区域。
    /// - 参数:
    ///   - rgba: 输入图像数据（预乘 RGBA，将被原地修改）
    ///   - mask: 二进制/软掩码（>0 表示填充区域）
    /// - 返回：成功时 1，无源补丁时 0，分配失败时抛出。
    static func fill(rgba: UnsafeMutablePointer<UInt8>, stride: Int,
                     mask: UnsafePointer<UInt8>, maskStride: Int,
                     width: Int, height: Int) throws -> Int
}
```

### 3.3 MorphologyOp（新增 — 用于 expand/contract selection-modify）

```c
// 使用 8-连通邻域对二进制掩码膨胀 N 像素。
// mask: 输入二进制掩码（255 = 前景，0 = 背景）。
// output: 输出缓冲区，width * height 字节，由调用者分配。
// radius: 膨胀/腐蚀距离（像素），>0。
// 返回：成功时 0，无效参数时 -1。
void morph_dilate(const uint8_t *mask, size_t width, size_t height,
                  uint8_t *output, int radius);

// 使用 8-连通邻域对二进制掩码腐蚀 N 像素。
// 签名与 dilate 相同；输出为腐蚀后的掩码。
void morph_erode(const uint8_t *mask, size_t width, size_t height,
                 uint8_t *output, int radius);
```

**CLI Swift 包装器签名：**

```swift
enum MorphologyOp {
    /// 使用 8-连通邻域对二进制掩码膨胀（扩展）N 像素。
    static func dilate(_ mask: [UInt8], width: Int, height: Int, radius: Int) throws -> [UInt8]

    /// 使用 8-连通邻域对二进制掩码腐蚀（收缩）N 像素。
    static func erode(_ mask: [UInt8], width: Int, height: Int, radius: Int) throws -> [UInt8]
}
```

**实现说明：**
- CLI 中的 `percent` 模式（`--amount 10 --unit percent`），先转换为像素：`pixels = round(amount * width / 100.0)`
- 两个操作都是迭代式的：每次膨胀/腐蚀的每个像素在二进制掩码上实现为单次通过的方框滤波器，使用两个缓冲区（乒乓）重复 `radius` 次

### 3.4 SobelOp（新增 — 用于 edge-snap selection-modify）

```c
// 使用 3×3 Sobel 核在每个像素处计算梯度幅值。
// image: 灰度输入（每像素 8-bit，每行 stride 字节）。
// edges: float 输出缓冲区，width * height 个元素，值在 [0, 1]。
// 返回：成功时 0，无效参数时 -1。
int sobel_edge_detect(const uint8_t *image, size_t width, size_t height, size_t stride,
                      float *edges, size_t edgesStride);

// 找到掩码中每个边界像素的最近高梯度位置。
// mask: 二进制/软掩码（0–255）。边界像素是那些值在 0 < value < 255 之间的像素。
// edges: sobel_edge_detect 输出的梯度幅值图（与掩码相同维度）。
// threshold: 算作"高"的最小梯度（0.0–1.0 归一化）。
// radius: 每个边界像素周围的搜索窗口（像素）。
// output: 输出掩码，其中边界像素已吸附到最近的高梯度位置。
// 返回：成功时 0，无效参数时 -1。
int snap_to_edges(const uint8_t *mask, const float *edges, size_t width, size_t height,
                  float threshold, int radius, uint8_t *output);
```

**CLI Swift 包装器签名：**

```swift
enum SobelOp {
    /// 从灰度图像计算边缘图。输出值在 [0, 1] 范围内。
    static func detectEdges(_ image: [UInt8], width: Int, height: Int) throws -> [Float]

    /// 将掩码边界像素吸附到 snapRadius 内的最近高梯度位置。
    static func snapToEdges(mask: [UInt8], edges: [Float], threshold: Float, radius: Int) throws -> [UInt8]
}
```

---

## 4. CoreIO API — 文件 I/O 签名

### 4.1 ImageExporter（新增 — 从桌面应用提取的写入函数）

```swift
/// 将 CGImage 写入给定 URL 的 PNG 文件。
enum ImageExporter {
    static func writePNG(_ image: CGImage, to url: URL) throws
}

/// 以指定质量（0–1）将 CGImage 写入 JPEG 文件。
extension ImageExporter {
    static func writeJPEG(_ image: CGImage, to url: URL, quality: Float) throws
}

/// 以打印尺寸将 CGImage 写入 PDF 文件。
extension ImageExporter {
    /// @param resolution 每英寸像素（默认 72）
    static func writePDF(_ image: CGImage, to url: URL, resolution: Double = 72) throws
}
```

**实现细节**：这些函数使用 CoreGraphics 的 `CGImageDestinationCreateWithURL`。它们是同步的，在文件写入期间阻塞调用线程（约 ~5–50ms，取决于图像大小）。

### 4.2 ProjectManifest（新增 — .comp 清单读写）

基于官方 Compositor 格式文档（`docs/writing-comp-files.md`）。

```swift
/// 解析后的 .comp 项目清单。从磁盘读取并写为 JSON。
struct ProjectManifest: Sendable, Codable {
    let format: String                    // 始终为 "com.compositor.project"
    let version: Int                      // 1–11（新保存使用 11）
    let colorSpace: String                // 当前为 "sRGB"
    let documentID: UUID
    let width: Int                        // 画布宽度（像素）
    let height: Int                       // 画布高度（像素）
    let resolution: Double                // 每英寸像素，默认 72
    var activeLayerID: UUID

    /// 自底向上渲染顺序的图层。
    var layers: [LayerRecord]

    struct LayerRecord: Sendable, Codable {
        let id: UUID                      // 必须与图像文件名匹配（不含 .png）
        let name: String
        var imageFile: String?            // 调整/文本图层为 nil
        var maskFile: String?             // 可选："<id>.mask.png"
        var maskEnabled: Bool = true      // 存在 maskFile 时默认为 true

        /// 图层外观（版本 3+）
        var opacity: Double = 1.0         // 钳位到 [0, 1]
        var blendMode: BlendMode = .normal

        /// 文档像素坐标中的图层变换（始终存在）
        let transform: Transform          // origin, size, rotation, flips, sampling

        /// 可选：调整图层设置（版本 7+）
        var adjustment: Adjustment?       // 普通图像层为 nil

        /// 可选：文本图层元数据（版本 10–11）
        var text: TextMetadata?           // content, font, size, color, alignment
    }

    enum BlendMode: String, Codable {
        case normal = "Normal", darken = "Darken"
        case multiply = "Multiply", colorBurn = "Color Burn", linearBurn = "Linear Burn"
        case screen = "Screen", colorDodge = "Color Dodge", linearDodgeAdd = "Linear Dodge (Add)"
        case overlay = "Overlay", softLight = "Soft Light", hardLight = "Hard Light"
        case vividLight = "Vivid Light", linearLight = "Linear Light", pinLight = "Pin Light"
        case hardMix = "Hard Mix", difference = "Difference", exclusion = "Exclusion"
        case subtract = "Subtract", divide = "Divide"
        case hue = "Hue", saturation = "Saturation", color = "Color", luminosity = "Luminosity"
    }

    struct Transform: Sendable, Codable {
        let origin: [Double]              // 文档像素中的 [x, y]
        let size: [Double]                // [width, height]
        let rotation: Double              // 度，顺时针
        let flipX: Bool, flipY: Bool
        let sampling: String              // "High quality", "Smooth", 或 "Nearest"
    }

    enum AdjustmentKind: String, Codable {
        case hueSaturation, levels, curves, exposure, gradientMap, grain
        case invert, blackWhite, colorBalance
        case gaussianBlur, motionBlur, addNoise
    }

    struct Adjustment: Sendable, Codable {
        let kind: AdjustmentKind
        // 字段因类型而异 — 见 ProjectManifest.Adjustment 获取完整 Schema。
        // 所有类型的公共关键字段：hue (±360), saturation/lightness (±100)。
        // Levels/Curves 有嵌套的通道特定设置。
    }

    struct TextMetadata: Sendable, Codable {
        let content: String
        let fontName: String              // PostScript 名称
        let fontSize: Double              // 像素为单位
        let red: Double, green: Double, blue: Double   // 0–1 颜色
        let alignment: String             // "Left", "Center", "Right"
        var tracking: Double = 0.0
        var lineSpacing: Double = 0.0
        var boxSize: [Double]?           // [width, height] 段落边界
    }
}

/// 从 .comp 文件夹路径读取清单。无效 JSON 或格式违规时抛出。
enum ProjectManifest {
    static func read(from packageURL: URL) throws -> ProjectManifest
}

/// 原子地将清单写入 .comp 文件夹（先写到临时文件，然后重命名）。
extension ProjectManifest {
    /// @param packageURL .comp 文件夹路径（例如 "project.comp"）
    /// @param layerImageURLs 图层 UUID → images/ 子文件夹中图像文件 URL 的映射。
    static func write(to packageURL: URL, manifest: ProjectManifest,
                      layerImageURLs: [UUID: URL]) throws
}
```

### 4.3 .comp 格式约束（来自官方文档）

| 约束 | 值 | 执行方式 |
|------|-----|---------|
| 画布最大边长 | 30,000 px | 如果 width/height > 30000 则拒绝清单 |
| 每层总源像素数 | 1 亿 | 如果 width × height > 100_000_000 则拒绝 |
| 最大图层数 | 10,000 | 如果 layers.count > 10000 则拒绝 |
| 清单大小限制 | 4 MiB | 文件 > 4MB 则拒绝 |
| 编码资源大小限制 | 512 MiB | 图像文件 > 512MB 则拒绝 |
| PNG 格式 | 图像的 8-bit RGBA，掩码的灰度 | 读取时验证 |
| 图像目录 | 包根目录下的 `images/` 子文件夹 | 硬编码路径 |
| 图层 ID → 文件名映射 | `<UUID>.png`，大写 UUID | 写入前验证 |

---

## 5. Inpainting 引擎 API — LaMa 预处理与后处理

### 5.1 LaMaPreprocessor（新增 — 将 CGImage + SoftMask 转换为 MLX tensors）

```swift
/// 为 LaMa 推理准备图像和掩码。处理填充、缩放和张量转换。
enum LaMaPreprocessor {
    /// 将图像+掩码填充到 `resolution` 大小的正方形。保留宽高比，使用信箱填充（黑色 = 0）。
    /// - 返回：填充的图像 tensor (H, W, C)，填充的掩码 tensor (H, W)，以及用于反向变换的裁剪矩形。
    static func prepare(image: CGImage, mask: SoftMask, resolution: Int) throws -> (imageTensor: MLXArray, maskTensor: MLXArray, cropRect: CGRect)

    /// 推理后将结果图像缩放回原始尺寸。
    /// - 参数:
    ///   - result: LaMa 输出 tensor，形状为 (resolution, resolution, 3)
    ///   - cropRect: prepare() 返回的矩形 — 定义填充了哪个区域
    ///   - originalWidth/height：填充前的原始图像尺寸
    /// - 返回：匹配原始图像尺寸的 CGImage
    static func postprocess(result: MLXArray, cropRect: CGRect, toOriginalWidth width: Int, height: Int) throws -> CGImage
}
```

**预处理细节（信箱填充）：**
1. 计算缩放因子：`scale = resolution / max(image.width, image.height)`
2. 新尺寸：`newW = round(originalWidth * scale)`, `newH = round(originalHeight * scale)`
3. 将缩放的图像居中放置在 `resolution × resolution` 正方形中；填充区域 = 0（图像为黑色，掩码为 0）
4. 转换为 MLX tensor：归一化 RGB 到 [0, 1] 范围（`pixel / 255.0`）
5. 对掩码 tensor 应用相同的居中填充

**后处理细节（边界混合）：**
1. 使用 `cropRect` 从填充区域裁剪结果回 `newW × newH`
2. 使用双线性插值缩放到原始尺寸
3. 混合边界像素：对于距填充边框 8px 内的每个像素，使用 σ = 4 的高斯权重在原始图像和 LaMa 输出之间混合（因此在 8px 距离处，权重 ≈ 0.135 → 主要是原始图像）

### 5.2 LaMaPostprocessor — 边界混合公式

```swift
/// 混合源（原始）和结果（LaMa 输出）之间的边界像素。
/// 使用宽度为 `blendWidth`（默认 8px）的高斯加权过渡区。
func blendBoundary(source: UnsafePointer<UInt8>, result: UnsafePointer<UInt8>,
                   mask: UnsafePointer<UInt8>, stride: Int,
                   width: Int, height: Int, blendWidth: Int = 8) -> [UInt8] {
    let output = [UInt8](repeating: 0, count: width * height * 4)

    for y in 0..<height {
        for x in 0..<width {
            let idx = (y * width + x) * 4
            // 距填充边框的距离：min(x, y, width-1-x, height-1-y)
            let distToBorder = min(min(x, y), min(width - 1 - x, height - 1 - y))

            if distToBorder >= blendWidth {
                // 混合区外：完全使用结果
                output[idx...idx+3] = result[idx...idx+3]
            } else {
                // 混合区内：高斯权重
                let t = CGFloat(distToBorder) / CGFloat(blendWidth)   // 边界处为 0，内部为 1
                let sigma: CGFloat = 4.0
                let weight = exp(-0.5 * pow((t - 1.0) / sigma, 2)) // 靠近边框 → 结果的权重低

                // 混合：source * (1-weight) + result * weight
                for c in 0..<4 {
                    output[idx+c] = UInt8(round(Double(source[idx+c]) * (1 - Double(weight)) + Double(result[idx+c]) * Double(weight)))
                }
            }
        }
    }
    return output
}
```

---

## 6. CLI 命令层 API — 薄包装器

### 6.1 ExtractCommand

```swift
enum ExtractCommand {
    /// 执行主体提取并将结果写入磁盘。
    static func run(inputURL: URL, model: ModelChoice, refineRadius: Int,
                    contrastThreshold: Float, edgeShift: Int, outputURL: URL) throws -> CommandResult
}

enum ModelChoice: String {
    case vision            // Apple Vision Framework（内置，无需下载）
    case sam2Lightweight   // MLX SAM2 模型（~35MB，首次使用时下载）
}
```

**执行流程：**
1. 读取图像 → CoreGraphics (`CGImageSourceCreateWithURL`) → `CGImage`
2. 选择引擎：`VisionSegmentationEngine()` 或 `SAM2SegmentationEngine(modelURL:)`
3. 引擎产生 `SoftMask`
4. 如果 `refineRadius > 0`：应用 `GuidedMatte.refine(mask:guide:radius:limit)` → 细化后的 SoftMask
5. 通过 `SoftMask.pixels.map { clamp(...) }` 应用对比度阈值和边缘偏移
6. 调用 `ImageExporter.writePNG(mask.asCGImage(), to: outputURL)`

### 6.2 InpaintCommand

```swift
enum InpaintCommand {
    /// 执行修复并将结果写入磁盘。
    static func run(imageURL: URL, maskURL: URL, algorithm: InpaintingAlgorithm, outputURL: URL) throws -> CommandResult
}

enum InpaintingAlgorithm {
    case patchBased        // content_fill.c — Phase 1（内置）
    case lama(preset: LaMaPreset)   // MLX 推理 — Phase 2+（需要下载）
}

struct LaMaPreset: Sendable {
    let resolution: Int       // 512, 1024, 或 2048
    let iterations: Int       // 4, 8, 或 16
}
```

**执行流程：**
1. 读取图像 → `CGImage`，读取掩码 → `SoftMask`
2. 验证尺寸匹配（不匹配则抛出 `dimensionMismatch`）
3. 选择引擎并运行修复
4. 通过 `ImageExporter.writePNG(...)` 写入结果

### 6.3 SelectionModifyCommand

```swift
enum SelectionModifyCommand {
    /// 对输入执行选区操作并将输出写入磁盘。
    static func run(inputURL: URL, operation: SelectionOperation, params: SelectionParams, outputURL: URL) throws -> CommandResult
}

enum SelectionOperation: String {
    case expand, contract, feather, edgeSnap, wand
}

struct SelectionParams: Sendable {
    // 用于 expand/contract：
    let amount: Double
    let unit: AmountUnit   // .pixels 或 .percent

    // 用于 feather：
    let blurSigma: Double  // 像素中的高斯 σ

    // 用于 edge-snap：
    let guideURL: URL?     // nil = 使用输入自身的亮度
    let threshold: Float   // 0.1–1.0 梯度阈值
    let snapRadius: Int    // 搜索窗口，默认 5

    // 用于 wand：
    let point: CGPoint     // 点击位置 (x, y)，以图像像素坐标为单位
    let tolerance: Int     // 0–255 每通道差异
    let sampleSizeRadius: Int   // 0=点，1=3×3，2=5×5
    let contiguous: Bool        // 连通泛洪填充 vs 全局匹配
}
```

**执行流程：**
1. 读取输入（expand/contract/feather/edgeSnap 用掩码；wand 用图像）
2. 使用 CoreRendering 函数应用操作
3. 通过 `ImageExporter.writePNG(...)` 写入输出

### 6.4 ExportCommand

```swift
enum ExportCommand {
    /// 渲染项目或单张图像并以指定格式写入磁盘。
    static func run(inputURL: URL, format: OutputFormat, quality: Float?, scale: Double?, outputURL: URL) throws -> CommandResult
}

enum OutputFormat: String {
    case png, jpeg, pdf

    /// 从文件扩展名推断格式。无法识别时默认为 PNG。
    static func infer(from url: URL) -> OutputFormat
}
```

**执行流程：**
1. 如果输入是 `.comp` 文件夹：读取清单 + 渲染所有图层（使用混合模式、变换、掩码合成）→ 单个 `CGImage`
2. 如果提供了 scale，应用缩放
3. 通过相应的 `ImageExporter` 函数写入

---

## 7. 错误类型 — 统一 CoreError

```swift
enum CoreError: LocalizedError {
    case fileNotFound(path: String)
    case invalidImageFormat(url: URL, reason: String?)     // 解码为图像失败
    case dimensionMismatch(image: (Int, Int), mask: (Int, Int))  // width/height 不匹配
    case renderFailed(reason: String)                       // CGContext 或 CGImageDestination 失败
    case modelMissing(key: String)                          // SAM2/LaMa 权重未找到

    var errorDescription: String? { ... }
}
```

所有 CLI 命令将 `CoreError` 映射到 `CommandError`（command-spec.md 中的 JSON 可序列化类型）。映射是一对一的，除了 `modelMissing` 额外添加下载提示。

---

## 8. 时序阶段 — 每个命令的精确阶段名称

用于 JSON 输出中的 `timing.phases[].name`：

| 命令 | 阶段序列（始终按此顺序） |
|------|------------------------|
| `extract` | `read_input`, `segmentation`, `refinement`（可选）, `write_output` |
| `inpaint` | `read_input`, `inpainting`, `write_output` |
| `selection-modify:expand/contract` | `read_input`, `morphology`, `write_output` |
| `selection-modify:feather` | `read_input`, `blur`, `write_output` |
| `selection-modify:edge-snap` | `read_input`, `sobel_compute`, `snap`, `write_output` |
| `selection-modify:wand` | `read_input`, `selection`, `write_output` |
| `export` | `read_input`, `render`（或 .comp 的 `composite_project`）, `write_output` |
| `models list` | `read_manifest`, `complete` |
| `models download` | `download`, `verify_hash`, `move_to_final_location`, `complete` |
