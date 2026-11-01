# 项目结构

## 仓库布局

```
Compositor/                                    # 已有仓库（不变）
├── Compositor.xcodeproj
├── Compositor/                                # 桌面应用源码
│   ├── CompositorApp.swift
│   ├── ContentView.swift
│   ├── Document/                              # ← 将被部分提取
│   ├── IO/                                    # ← 将被部分提取
│   └── Rendering/                             # ← 将被部分提取
├── CompositorTests/
├── scripts/
└── docs/

compositor-cli-spec/                           # 本规范仓库
├── README.md                                  # 快速入门 / 概览
├── docs/
│   ├── architecture.md                        # 系统设计、分层架构、数据流
│   ├── command-spec.md                        # 完整 CLI 命令参考
│   ├── core-extraction.md                     # CompositorCore 提取方案
│   ├── engine-layer.md                        # ML 推理引擎协议与实现
│   ├── project-structure.md                   # 本文件：仓库布局与构建配置
│   └── implementation-roadmap.md              # 分阶段时间表，含里程碑
├── examples/
│   ├── agent-prompt-template.md               # 调用 CLI 的 LLM 系统提示模板
│   └── sample-scripts/                        # Agent 可生成的 JSON 脚本
│       ├── extract-subject.json
│       └── remove-object.json
└── prototypes/                                # 参考实现（可选）
    └── mlx-conversion/                        # PyTorch → MLX 权重转换工具
        ├── convert_lama.py
        └── convert_sam2.py
```

## Xcode 项目配置（提取后）

桌面应用的 `Compositor.xcodeproj` 新增两个 Target：

```
Compositor.xcodeproj/
├── Compositor                    # 已有 — macOS 应用，SwiftUI
├── CompositorTests               # 已有 — XCTest
│
├── CompositorCore                # 新 — Swift Package（静态框架）
│   ├── Target: CompositorCore
│   ├── Source:
│   │   ├── CoreDocument/         ← Document/ 中的纯数据模型
│   │   ├── CoreRendering/        ← C 像素操作 + 无头渲染器
│   │   └── CoreIO/               ← 文件导入/导出（无 AppKit）
│   └── Settings:
│       ├── SWIFT_ACTIVE_COMPILATION_CONDITIONS = COMPOSITOR_CORE
│       ├── ENABLE_TESTING = YES
│       └── 通过构建脚本禁止 UI 框架引入
│
├── CompositorCLI                 # 新 — macOS 可执行文件
│   ├── Target: CompositorCLI
│   ├── Source:
│   │   ├── CompositorCLI.swift   ← @main，ArgumentParser 入口点
│   │   ├── Commands/             ← extract, inpaint, selection-modify, export, models
│   │   ├── Engines/              ← SegmentationEngine, InpaintingEngine 协议与实现
│   │   └── Ops/                  ← SobelOp, SelectionOps（传统图像处理操作）
│   └── Dependencies:
│       ├── CompositorCore
│       ├── MLX（通过 SPM 引入，若无则使用二进制框架）
│       └── ArgumentParser（SPM）
```

## Swift Package Manager 依赖

### 仅针对 CompositorCLI Target

```swift
// Package.swift 片段（或 Xcode SPM 依赖配置）
.package(url: "https://github.com/apple/swift-argument-parser", from: "1.4.0"),
.package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.21.0"),  // 或使用最新稳定版
```

### 仅针对 CompositorCore Target

无外部依赖。纯 Swift + 嵌入式 C 文件。

### 桌面应用（Compositor）Target

依赖不变。可选择性依赖 `CompositorCore` 以复用共享逻辑。

## 构建脚本

### 验证 Core 不含 UI 代码（Phase 0+）

```bash
# scripts/verify-core-no-ui.sh
#!/bin/zsh
set -e
# 检查 Xcode 项目中 CompositorCore Target 目录
CORE_PATH="Compositor.xcodeproj/../CompositorCore"
if [ ! -d "$CORE_PATH" ]; then
    echo "SKIP: CompositorCore 尚未创建（Phase 0 未开始）"
    exit 0
fi
if grep -rn "import AppKit\|import SwiftUI" "$CORE_PATH/" --include="*.swift"; then
    echo "FATAL: CompositorCore 禁止引入 UI 框架"
    exit 1
fi
echo "PASS: CompositorCore 不含 UI 代码"
```

### 仅运行 Core 测试（Phase 0+）

```bash
# scripts/test-core-only.sh
xcodebuild test \
    -project Compositor.xcodeproj \
    -scheme CompositorCore \
    -destination 'platform=macOS' \
    ONLY_ACTIVE_ARCH=YES
```

## CI 流水线（GitHub Actions）

```yaml
# .github/workflows/cli-spec-build.yml（在 compositor-cli-spec 仓库中，或添加到主仓库）
name: CLI Spec Build
on: [push, pull_request]
jobs:
  verify-core:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/verify-core-no-ui.sh
  test-core:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/test-core-only.sh
  build-cli:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          xcodebuild build \
            -project Compositor.xcodeproj \
            -scheme CompositorCLI \
            -destination 'platform=macOS'
```

## 分发

### Homebrew Cask（主要方式）

```ruby
cask "compositor-cli" do
  version "0.1.0"
  sha256 "..."

  url "https://github.com/robbietilton/CompositorCLI/releases/download/v#{version}/CompositorCLI-#{version}.dmg"
  name "Compositor CLI"
  desc "面向 AI Agent 的确定性图像处理工具"

  app "Compositor CLI.app"
end
```

### 直接下载

GitHub Releases 包含：
- `CompositorCLI-<version>.dmg` — macOS 包（已签名 + 公证）
- `models-sam2-lightweight-<version>.safetensors` — 可选模型包
- `models-lama-fast-<version>.safetensors` — 可选模型包

### Agent 安装流程

```bash
# Agent 可假设 CLI 安装在以下路径：
/usr/local/bin/compositor

# 若不存在，Agent 指示用户执行：
brew install --cask compositor-cli

# 模型由 CLI 在首次使用时自动下载。
# 也可由用户预先下载：
compositor models download sam2-lightweight
compositor models download lama-fast
```

## 版本管理

遵循语义化版本控制规范：

| 版本号 | 范围说明 |
|--------|---------|
| `0.x.y` | 1.0 之前。允许破坏性命令变更，但每次发布会文档说明 |
| `1.x.y` | API 稳定版。除非主版本升级，否则命令、参数和 JSON 输出格式冻结 |
| 补丁 (y) | 仅修复 Bug，不改变行为 |

`command-spec.md` 中的 JSON 输出 Schema 在 v1.0+ 属于稳定契约的一部分。在此之前，次版本号递增可能调整字段名或添加新字段。
