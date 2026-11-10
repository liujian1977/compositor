# Compositor CLI 规范说明

面向 AI Agent 的确定性图像处理命令行工具。基于 [Compositor](https://github.com/robbietilton/Compositor) —— 一款免费开源的 macOS 图像编辑器构建。

## 项目定位

一套提供精确、可验证图像操作的命令行接口：主体提取、物体移除（修复）、选区操作和导出。每个命令都是纯函数——相同输入 + 参数始终产生相同输出。

设计为 LLM Agent 调用，而非人类直接操作。Agent 负责语义理解（"把这张照片里的人去掉"）并转换为精确的 CLI 命令（`compositor extract --input ... --model vision --refine-radius 3`）。

## 快速开始（面向 Agent）

```bash
# 提取主体掩码，再写成透明 PNG
compositor extract --input photo.jpg --output mask.png
compositor cutout --image photo.jpg --mask mask.png --output subject.png

# 查看蒙版覆盖率、外接框和连通域（stdout 是 JSON）
compositor inspect --input mask.png

# 移除物体
compositor inpaint --image scene.jpg --mask obj_mask.png --algorithm lama --output cleaned.png

# 扩展选区 10 像素
compositor selection-modify --input sel.png --operation expand --amount 10 --unit pixels --output expanded.png

# JSON 格式输出便于解析
compositor extract --input photo.jpg --output mask.png --format json
```

## 架构概览

```
LLM Agent (意图, 参数)    →    CLI (确定性操作)    →    像素级输出
```

完整系统设计见 [docs/architecture.md](docs/architecture.md)。

## 命令参考

完整的命令参考，包含每个参数和错误情况：[docs/command-spec.md](docs/command-spec.md)。

## 项目文件

| 文件 | 用途 |
|------|------|
| [docs/architecture.md](docs/architecture.md) | 系统设计、分层架构、数据流、模型管理 |
| [docs/command-spec.md](docs/command-spec.md) | 完整 CLI 命令参考（每个标志位、错误情况、JSON Schema） |
| [docs/core-extraction.md](docs/core-extraction.md) | 从桌面应用提取 CompositorCore 的方案 |
| [docs/engine-layer.md](docs/engine-layer.md) | ML 推理引擎协议和实现 |
| [docs/project-structure.md](docs/project-structure.md) | 仓库布局、构建配置、CI、分发 |
| [docs/implementation-roadmap.md](docs/implementation-roadmap.md) | 分阶段时间表、里程碑、风险和风险登记册 |

## 设计原则

1. **精确优于灵活** —— 每个命令都是确定性映射 f(input, params) → output
2. **可选 ML 模型** —— 内置算法（Vision Framework、基于补丁的填充）无需下载即可工作；SAM2 和 LaMa 为可选安装
3. **Agent 优先接口** —— JSON 输出含时序数据，类型化错误含恢复提示
4. **无静默失败** —— 每个错误都包含机器可读的类型和可选恢复提示

## 许可证

本规范按"原样"提供，仅作设计参考。底层 Compositor 项目采用 MIT 协议许可。
