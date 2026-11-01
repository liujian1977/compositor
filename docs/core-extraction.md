# CompositorCore 提取方案

## 目标

从桌面应用中提取确定性、无 UI 的图像处理逻辑，构建成独立的 Swift Package（`CompositorCore`），CLI 和桌面应用均可依赖它。

**保留在桌面应用中的内容**：所有 SwiftUI 视图、AppKit 桥接、窗口管理、菜单命令、键盘快捷键、拖放处理器、剪贴板集成。

**移动到 CompositorCore 的内容**：文档模型、选区系统、图层操作、像素渲染（无头模式）、图像 I/O。

---

## 依赖关系图（目标状态）

```
CompositorCore/             ← Swift Package，静态框架
├── CoreDocument/           ← 纯数据模型 + 逻辑（无副作用）
│   ├── Selection.swift     ← DocumentSelection, DocumentSelectionClip
│   ├── Crop.swift          ← 画布裁剪几何
│   ├── CanvasSize.swift    ← width/height 值类型
│   ├── Guides.swift        ← 参考线位置与边界
│   ├── LayerAppearance.swift ← 透明度、混合模式枚举（仅参数）
│   └── LayerEffects.swift  ← 效果参数字段结构体（非渲染逻辑）
├── CoreRendering/          ← C 像素操作 + 无头合成
│   ├── *.c / *.h           ← AdjustPixels, BrushPixels, WandPixels, ContentFill 等
│   ├── BrushRaster.swift   ← CGContext 包装器用于像素绘制（仅 CoreGraphics）
│   └── TiledRenderer.swift ← 基于图块的图层合成（无视图展示）
├── CoreIO/                 ← 文件导入/导出（无 UI 对话框）
│   ├── ImageImporter.swift ← 基于 CGImageSource 的图像加载
│   ├── ImageExporter.swift ← writePNG/writeJPEG 函数（无保存面板）
│   ├── PSD/*.swift         ← PSD/PSB 二进制解析（8-bit RGB）
│   └── ProjectStore.swift  ← .comp 文件夹读写（无窗口管理）

CompositorCLI/              ← macOS 可执行文件，依赖 CompositorCore + Engines
Compositor.xcodeproj        ← 桌面应用 Target（依赖 CompositorCore，拥有 EditorSession）
```

---

## Core 代码规则

1. **禁止引入 AppKit/SwiftUI** — 通过构建脚本验证
2. **所有公开类型为 `Sendable`** — 或明确标注 `@unchecked Sendable` 并附文档说明原因
3. **确定性 I/O** — 给定相同文件路径 + 像素数据，操作产生完全相同的输出
4. **无单例状态** — 所有状态通过函数参数或值类型传递

---

## 分阶段提取

### Phase 1：纯数据模型（CoreDocument）

需要移动的文件，改动极小：

| 源文件 | 需一起移动的依赖 | 说明 |
|--------|-----------------|------|
| `Document/Selection.swift` | — | 已是纯代码，仅使用 CGImage |
| `Document/Crop.swift` | — | 仅几何操作 |
| `Document/CanvasSize.swift` | — | 值类型 |
| `Document/Guides.swift` | — | 点数组 + 边界 |
| `Document/LayerAppearance.swift` | — | 透明度、混合模式枚举 |
| `Document/LayerEffects.swift` | — | 仅效果**参数**（Stroke, DropShadow, ColorOverlay 等值类型）。渲染逻辑保留在 CoreRendering。 |

**留在桌面应用中的文件**（它们桥接 EditorSession）：

- `Document/EditorSession.swift` — 太多 AppKit 依赖（窗口状态、第一响应者、键盘快捷键）
- `Document/ShapeTool.swift`, `TypeTool.swift` — 需要文本布局引擎

### Phase 2：像素操作（CoreRendering）

需要移动的文件：

| 源文件 | 改动需求 | 说明 |
|--------|---------|------|
| 所有 `Rendering/*.c` / `*.h` | 无 | 已是纯 C，无 Objective-C 依赖 |
| `Rendering/BrushRaster.swift` | 移除可能存在的 `import AppKit` | 目前仅使用 CoreGraphics — 应该没问题 |
| `Rendering/LayerRenderer.swift` | 提取合成逻辑，移除视图展示 | 保留渲染管线；丢弃叠加绘制 |
| `Rendering/TiledLayerRenderer.swift` | 同上 | 基于图块的合成是纯数学计算 |

**留在桌面应用中的文件**：

- `Rendering/BrushCursorOverlay.swift` — UI 特定的光标渲染
- `Rendering/CanvasLinesOverlay.swift` — 标尺、参考线显示
- `Rendering/NavigatorMinimap.swift` — 缩略图视图
- `Rendering/GPUCanvas.swift` — Metal 视图集成（依赖 MTKView）

### Phase 3：文件 I/O（CoreIO）

需要移动的文件：

| 源文件 | 改动需求 | 说明 |
|--------|---------|------|
| `IO/ImageImporter.swift` | 验证无 AppKit 依赖 | 使用 CGImageSource — 应为纯代码 |
| `IO/ImageExporter.swift` | 验证无 AppKit 依赖 | 目前由桌面应用导出对话框使用；提取实际文件写入逻辑 |
| `IO/PSD/*.swift` | 无 | 纯二进制解析 |
| `IO/ProjectStore.swift` | 移除保存/打开中的窗口管理 | 保留 `.comp` 文件夹读写；将 `showSavePanel()` 移至桌面应用层 |

**留在桌面应用中的文件**：

- `IO/CompositorApplicationDelegate.swift` — App 生命周期、Sparkle 更新
- `IO/ImageFileDrop.swift` — NSDraggingReceiver 协议实现
- `IO/RecentProjects.swift` — UserDefaults + 窗口管理桥接

### Phase 4：EditorSession 分解（仅桌面应用）

这是最困难的部分。`EditorSession` 是一个约 2000 行的文件，混合了文档逻辑和 UI 状态。它保留在桌面应用中，但会被重构为依赖 CompositorCore 执行像素操作：

```swift
// 之前：EditorSession 包含自己的像素渲染代码
class EditorSession {
    func applyFilter(_ filter: FilterKind) -> Task { ... }       // 直接调用 CoreRendering？不，是内联代码
}

// 之后：EditorSession 委托给 Core 类型
class EditorSession {
    let document: Document           // 来自 CompositorCore.CoreDocument
    let renderer: TiledRenderer      // 来自 CompositorCore.CoreRendering
    
    func applyFilter(_ filter: FilterKind) -> Task { ... }   // 使用 renderer.apply(filter)
}
```

---

## 构建验证脚本

一个在每次构建时运行的脚本（`scripts/verify-core-no-ui.sh`），用于强制执行以下规则：

```bash
#!/bin/zsh
# Core Target 禁止引入 AppKit 或 SwiftUI
if grep -rn "import AppKit\|import SwiftUI" CompositorCore/; then
    echo "ERROR: CompositorCore 不得依赖 UI 框架"
    exit 1
fi
echo "OK: CompositorCore 不含 UI 代码"
```

---

## 迁移步骤（桌面应用）

CompositorCore 构建并独立测试通过后：

1. 在 `Compositor.xcodeproj` 中将 `CompositorCore` 添加为本地 Swift Package
2. 桌面应用 Target 添加对 `CompositorCore` 的依赖
3. 逐步将文件引用从 `Compositor/Document/...` 迁移到 `CompositorCore.CoreDocument/...`
4. 验证桌面应用仍可构建并通过所有测试（`CompositorTests`）
5. 将 CompositorCLI 包合并到同一 Xcode 项目（或保持为独立包）

**风险**：第 3 步可能涉及大量引用 `EditorSession` 的文件。关键洞察是：`EditorSession` 保留在桌面应用中——它只是不再包含像素级渲染代码，改为调用 Core API。

---

## CompositorCore 测试策略

| 测试 Target | 测试内容 | 框架 |
|------------|---------|------|
| `CompositorCoreTests/` | 纯逻辑单元测试（选区数学、滤镜参数、PSD 解析） | XCTest |
| `CompositorCoreIntegrationTests/` | 往返测试：加载图像 → 应用操作 → 逐像素验证输出与参考比对 | XCTest + 快照比较 |

**参考图片**：存储在 git LFS track 中或作为小型内嵌测试夹具（每个不超过 1MB）。每项测试都有一个预期 PNG，与输出进行字节级对比。

```
CompositorCoreTests/
├── SelectionTests.swift       // expand, contract, feather 数学计算
├── WandPixelTests.swift       // 泛洪填充正确性
├── GuidedMatteTests.swift     // 滤镜输出 vs 已知正确的 [Float] 数组
└── Fixtures/                  // 测试图片（git-lfs）
    ├── portrait_256x256.png
    └── landscape_512x384.jpg
```
