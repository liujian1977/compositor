# 实施路线图

## Phase 0：基础（第 1–2 周）

**目标**：提取 CompositorCore 并验证其可独立构建。

### 任务

1. 在 Xcode 项目中创建 `CompositorCore` Swift Package Target
2. 将纯数据模型移动到 `CoreDocument/`：
   - `Selection.swift` → `CoreDocument/Selection.swift`
   - `Crop.swift` → `CoreDocument/Crop.swift`
   - `CanvasSize.swift` → `CoreDocument/CanvasSize.swift`
   - `Guides.swift` → `CoreDocument/Guides.swift`
3. 将 C 像素操作移动到 `CoreRendering/`：
   - 从 `Rendering/` 移动所有 `*.c` / `*.h` 文件
4. 创建带空 `@main` stub 的 `CompositorCLI` Target
5. 编写并通过 `verify-core-no-ui.sh` 构建检查

### 里程碑

- `CompositorCore` 以静态框架形式构建，零 UI 引入
- 现有 `CompositorTests` 仍通过（桌面应用无回归）
- 空命令 `compositor --help` 打印帮助文本

---

## Phase 1：最小化 CLI — Export + Extract（第 3–5 周）

**目标**：首个可用版本。Agent 可提取主体和导出图像。

### 任务

#### 1.1 将现有图像 I/O 暴露为 CoreIO

- 验证 `ImageImporter.swift` 无 AppKit 依赖
- 从桌面应用导出对话框中提取文件写入逻辑到纯函数：
  ```swift
  // CompositorCore.CoreIO 中
  enum ImageExporter {
      static func writePNG(_ image: CGImage, to url: URL) throws
      static func writeJPEG(_ image: CGImage, to url: URL, quality: Float) throws
  }
  ```

#### 1.2 实现 `export` 命令

```swift
// CompositorCLI/Commands/ExportCommand.swift
struct ExportCommand: ParsableCommand {
    @Option var input: URL
    @Option var output: URL
    @Option var format: OutputFormat = .auto
    // ...
}
```

- 接受单个图像文件或 `.comp` 项目文件夹
- 使用 `ImageExporter` 写入输出
- 支持 `--format json` 输出

#### 1.3 实现 `extract` 命令（仅 Vision 模型）

- 创建实现 `SegmentationEngine` 的 `Engines/VisionSegmentationEngine.swift`
- 在 `Commands/ExtractCommand.swift` 中接入：
  - 读取输入图像 → 调用引擎 → 获取 SoftMask → 写入 PNG 掩码
- 当 `--refine-radius > 0` 时应用 GuidedMatte 细化

#### 1.4 编写基础测试

```swift
// CompositorCoreTests/SelectionTests.swift
test("expand adds N pixels to boundary") { ... }
test("feather applies Gaussian blur with correct sigma") { ... }

// CompositorCLITests/ExtractCommandTests.swift
test("extract produces valid PNG mask for portrait image") { ... }
```

### 里程碑

- `compositor extract --input photo.jpg --output mask.png` 端到端可用
- `compositor export --input result.png --output result.jpg` 端到端可用
- 成功时退出码 0，失败时退出码 1。JSON 输出匹配规范 Schema。

---

## Phase 2：Inpainting + Selection Ops（第 6–9 周）

**目标**：Agent 可移除物体并精确操作选区。

### 任务

#### 2.1 使用基于补丁的算法实现 `inpaint` 命令

- 复用现有 `content_fill.c` 作为默认引擎（`PatchBasedInpaintingEngine`）
- 无需新依赖——这是桌面应用的内容感知填充，通过 CLI 暴露

#### 2.2 集成 LaMa 模型

- 创建 `convert_lama.py` 原型：PyTorch `.pth` → MLX safetensors
- 实现 `LaMaInpaintingEngine`：
  - 从 `~/Library/Application Support/Compositor/models/lama-fast.mlx/` 加载模型
  - 预处理（填充到正方形、缩放）
  - 通过 MLX 推理
  - 后处理（裁剪、缩放、边界混合）
- 在 `compositor models download lama-fast` 中添加模型下载逻辑

#### 2.3 实现 selection-modify 操作

```swift
// CompositorCLI/Commands/SelectionModifyCommand.swift
struct SelectionModifyCommand: ParsableCommand {
    @Option var input: URL
    @Argument var operation: SelectionOperation  // expand|contract|feather|edge-snap|wand
    // ...
}
```

- **expand / contract**：使用二进制掩码上的形态学操作实现（C 函数或 Swift 循环）——在 CoreRendering 中添加为 `morphology.c`
- **feather**：复用 Selection.swift 中现有的 CoreImage `gaussianBlur` 逻辑（通过 CoreRendering 暴露）
- **wand**：将现有 `MagicWand.select(in:at:settings:)` 暴露为 CLI 命令（已在 CompositorCore 中）
- **edge-snap**（Phase 2.5）：在 C 中实现 Sobel 算子 + 边界搜索

#### 2.4 为 edge-snap 实现 Sobel 边缘检测

```c
// CoreRendering/SobelOp.c
void sobel_edge_detect(const uint8_t *image, int width, int height, int bytesPerRow,
                       float *edges, int edgesBytesPerRow);
```

- 在每个像素处计算梯度幅值（3×3 Sobel 核）
- 输出：灰度图像，值 = 边缘强度 [0, 1] 归一化

#### 2.5 实现 edge-snap 操作

- 从 `--guide` 图像读取 Sobel 输出（如无 guide 则转换输入掩码的亮度）
- 对输入掩码中的每个边界像素，在 `--snap-radius` 内搜索梯度 > `--sobel-threshold` 的最近像素
- 将边界移动到该位置；如有需要则插值（离散边缘位置间的双线性插值）

#### 2.6 实现 expand / contract 操作

```c
// CoreRendering/MorphologyOp.c
void morph_dilate(const uint8_t *mask, int width, int height, uint8_t *output, int radius);
void morph_erode(const uint8_t *mask, int width, int height, uint8_t *output, int radius);
```

- 8-连通邻域膨胀/腐蚀。对于百分比模式，先将 amount 转换为像素（image width 的 amount%）。

### 里程碑

- 全部四个命令（`extract`, `inpaint`, `selection-modify`, `export`）功能可用
- LaMa 模型在首次使用时下载并端到端工作
- JSON 输出包含所有命令的时序数据

---

## Phase 3：SAM2 + 打磨（第 10–13 周）

**目标**：高质量分割选项 + CLI 可用性打磨。

### 任务

#### 3.1 集成 SAM2 移动端模型

- 创建 `convert_sam2.py` 原型：SAM2 PyTorch → MLX safetensors
- 实现 `SAM2SegmentationEngine`：
  - "全有"模式（全局分割不需要提示）
  - 选择最大掩码作为前景
- 添加模型下载逻辑

#### 3.2 CLI 可用性改进

- 添加带 stderr 进度报告的 `--verbose` 标志
- 改进行动性强的错误消息
- 通过 ArgumentParser 内置支持添加补全脚本（zsh, bash）

#### 3.3 集成测试

```swift
// CompositorCoreIntegrationTests/ExtractRoundTrip.swift
test("extract portrait → mask matches reference within tolerance") { ... }
test("inpaint small hole with patch-based produces deterministic output") { ... }
```

- 参考图片以 git-lfs fixtures 存储（每个不超过 1MB）
- 逐像素比较，浮点运算允许 ±2 偏差

#### 3.4 Agent 提示模板

编写 `examples/agent-prompt-template.md`——一个系统提示，教导 LLM Agent 如何使用 CLI：

```markdown
You have access to the Compositor CLI tool. It performs deterministic image processing.

Available commands:
- compositor extract --input X --output Y [--model vision|sam2-lightweight] ...
- compositor inpaint --image X --mask Y --output Z [--algorithm patch-based|lama] ...
- compositor selection-modify --input X --operation expand/contract/feather/wand/edge-snap ...
- compositor export --input X --output Y [--format png|jpeg|pdf]

Rules:
1. Each command is a pure function — same input always produces same output
2. Models are optional; default to "vision" for extract unless user asks for higher quality
3. If a model is missing, suggest the download command from the error hint
4. JSON output (--format json) returns structured results with timing data
```

#### 3.5 Homebrew Cask 打包

- 创建适配 CLI（无 GUI 组件）的 `scripts/dmg` 构建脚本
- 对 CLI bundle 签名并公证
- 发布首个版本到 Homebrew cask 仓库

### 里程碑

- 全部三种分割/修复模型可用：Vision、SAM2、LaMa
- CLI 可通过 Homebrew 安装
- Agent 提示模板在真实 LLM Agent 循环中测试通过
- 发布 v0.1.0

---

## Phase 4：未来（v1 之后）

这些不在初始发行范围内，但保留供参考：

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 批量处理（`--input-dir`） | 低 | Agent 很少需要；单图每命令对重试逻辑更清晰 |
| 通过 CLI 的多层合成 | 中 | 需要完整的 `.comp` 项目操作 API |
| OpenCV Telea/NS 算法 | 中 | `content_fill.c` 已覆盖基于补丁的方法；Telea/NS 是增量改进 |
| 实时进度流式传输 | 低 | CLI 是每次调用独立的；单次命令内的进度比批量 API 更重要 |
| gRPC / WebSocket 服务器模式 | 低 | 会改变范式——从"Agent 调用 CLI"变为"CLI 连接 Agent"——不同的权衡取舍 |

---

## 风险登记册

| 风险 | 影响 | 缓解措施 |
|------|------|---------|
| CompositorCore 提取比预期复杂，因为 EditorSession 纠缠 | Phase 1 延迟 2–3 周 | 渐进式提取：先从 `export`（不需要 Core）开始，然后逐个提取模型 |
| MLX 不支持所选的模型架构 | SAM2 或 LaMa 无法加载 | 回退方案：ONNX Runtime iOS 作为备选后端；SAM2 和 LaMa 都有 ONNX 导出 |
| 模型转换脚本无法产生可用的权重 | Phase 3 阻塞 | 在 Mac 上预转换模型并在发行中附带预构建的 safetensors；转换脚本尽力即可 |
| Vision Framework 对某些图像返回质量差的掩码 | 用户/Agent 对默认 `--model vision` 不满 | 清晰记录限制；确保 SAM2 下载无摩擦（一条命令） |
| Core 提取后桌面应用损坏 | 现有功能回归 | 每个阶段里程碑必须通过完整的 CompositorTests 套件；CI 强制执行 |
