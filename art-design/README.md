# art-design 艺术创作技能框架

一套 CodeBuddy 艺术创作技能 + 脚本/工具，可从本仓库一键安装到另一台 macOS。

## 安装
```bash
git clone https://github.com/liujian1977/compositor.git
cd compositor/art-design
./install.sh
```

## 文档
- **[spec.md](spec.md)** — 完整安装规范（agent 可读并按此完成安装；含组件清单、已装检查、配置、验证、排查）
- **[setup.sh](setup.sh)** — 交互注入 API key / 服务 URL（写入本机 600 权限文件，**不入库**）
- **[install.sh](install.sh)** — 自动化安装（实现 spec，幂等，优先跳过已装组件）

## 原则
- 任何 API key 与服务 URL **都不写进仓库文件**；由 `setup.sh` 在目标机注入到
  `~/.codebuddy/assets/art-design/local_config.json` 与 `comfyui_1238.key`。
- 安装目标：`~/.codebuddy/skills/`、`~/.codebuddy/assets/art-design/`、`~/.venv-art`、
  `~/.codebuddy/bin/compositor`。

## 包含
14 个技能（domain-knowledge / visual-qa / gimp-processing / prompt-engineering /
unified-workflow / artistic-text-generation / baoyu-article-illustrator / baoyu-comic /
baoyu-infographic / creative-ideation / gimp-layered-psd-cli / pixel-art /
semantic-gimp-artistic-stylization / visual-brand-collateral-design）、知识库
（knowledge.db）、YOLOv8n 权重、ComfyUI 客户端脚本，以及 compositor CLI 源码（仓库根）。
