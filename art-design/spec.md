# art-design 框架安装规范（spec）

本仓库 `art-design/` 子目录包含一套 CodeBuddy 艺术创作技能框架及其全部脚本/工具。
另一个 agent 只需 `git clone` 本仓库（compositor），按本规范即可在 macOS 上**完整安装**框架与工具。

> 本框架**不在任何仓库文件中硬编码 API key 或服务 URL**。所有密钥/URL 由 `setup.sh`
> 在目标机上交互输入，写入本机 `~/.codebuddy/assets/art-design/local_config.json`（600 权限）。

## 1. 仓库布局

```
compositor/                 (仓库根 = compositor Swift CLI 源码)
├── Package.swift, src/ …   (compositor 工具源码，install 时就地编译)
└── art-design/             (本框架)
    ├── spec.md             ← 你正在读的安装规范
    ├── install.sh          ← 自动安装（实现本规范，幂等）
    ├── setup.sh            ← 注入密钥/URL（不入库）
    ├── requirements.txt    ← Python 依赖
    ├── example-local_config.json  ← local_config 占位模板（无真实值）
    ├── skills/             ← 14 个 CodeBuddy 技能目录
    └── assets/             ← knowledge.db / yolov8n.pt / comfyui_generate.py
```

## 2. 前置条件（目标机）

- macOS（框架的 GIMP script-fu 与 `~/.codebuddy` 路径均按 macOS 设计）
- Xcode Command Line Tools（`swift` 命令）：`xcode-select --install`
- Python 3.11+（用于建 venv；macOS 自带没有则另装）
- GIMP 2.10（`.app` 包）：https://www.gimp.org/downloads/ —— **只能手动装**，脚本仅检查
- 网络可达你的 ComfyUI 服务与多模态 LLM 服务（地址/密钥由 setup.sh 输入）

## 3. 安装（二选一）

### 方式 A：自动（推荐）
```bash
git clone https://github.com/liujian1977/compositor.git
cd compositor/art-design
./install.sh            # 末尾会调用 setup.sh 让你输入密钥/URL
```
`install.sh` 幂等：每个组件**先检查是否已存在，存在则跳过**，可反复运行。
跳过密钥输入：`install.sh --no-setup`（之后手动 `./setup.sh`）。

### 方式 B：按规范手工安装（agent 逐步执行）
逐组件按第 4 节操作；每步先检查再动作，效果与 install.sh 一致。

## 4. 组件安装细节

| 组件 | 安装目标 | 检查方式 | 获取来源 |
|------|----------|----------|----------|
| 14 个技能 | `~/.codebuddy/skills/<name>` | 目录已存在？ | `art-design/skills/*` `cp -R` |
| 资产 | `~/.codebuddy/assets/art-design/{knowledge.db,yolov8n.pt,comfyui_generate.py}` | 文件已存在？ | `art-design/assets/*` `cp` |
| Python 环境 | `~/.venv-art` | 存在且 `import PIL,numpy,cv2,ultralytics,requests` 成功？ | `python3 -m venv` + `pip install -r requirements.txt` |
| compositor CLI | `~/.codebuddy/bin/compositor`（软链到仓库 `.build/debug/compositor`） | 该路径可执行？ | 仓库根 `swift build` |
| GIMP 2.10 | `/Applications/GIMP.app` | 存在？ | 手动下载安装（脚本不代装） |
| 密钥/URL | `~/.codebuddy/assets/art-design/local_config.json` + `comfyui_1238.key` | 文件已存在？ | `setup.sh` 交互写入 |

**compositor 编译**：仓库根即 Swift 包，`swift build` 产物在 `.build/debug/compositor`；
install 将其软链到 `~/.codebuddy/bin/compositor`。脚本通过 `$COMPOSITOR_BIN` 环境变量或默认该路径调用。
若 `swift` 不存在 → 先 `xcode-select --install`。

**资产**中**不包含**任何密钥：真实密钥文件（`comfyui_1238.key`、`local_config.json`、
`github_pat.txt`、`git_cred_helper.sh`、`.lock`、`.meta.json`）均不入库，仅 `example-local_config.json`
模板入库（占位、无真实值）。

## 5. 配置（密钥/URL 注入）

运行 `setup.sh`（install.sh 默认会调用；或单独运行）：
1. 输入 ComfyUI base URL（如 `http://host:1238`）
2. 输入 ComfyUI API key（X-API-Key 头，隐藏输入）
3. 可选：逐条输入多模态 LLM 端点 URL + API key（用于视觉 QA 主观评分），留空结束

写入：
- `~/.codebuddy/assets/art-design/comfyui_1238.key`（600）
- `~/.codebuddy/assets/art-design/local_config.json`（600）：
  ```json
  {"comfyui_base":"…","comfyui_key_path":"~/.codebuddy/assets/art-design/comfyui_1238.key",
   "llm_endpoints":[{"url":"…","apiKey":"…","id":"…","supportsImages":true}]}
  ```

运行时，`comfyui_generate.py` 与 `visual_quality_assessor.py` 从该文件读 URL/key，**从不读仓库文件**。
LLM 端点亦可来自 CodeBuddy 自带的 `~/.codebuddy/models.json`（支持 `supportsImages` 的条目）。

## 6. 验证

```bash
# 资产可读
~/.venv-art/bin/python -c "import sqlite3; sqlite3.connect('$HOME/.codebuddy/assets/art-design/knowledge.db'); print('kb ok')"
# compositor 可用
~/.codebuddy/bin/compositor --help
# 生图（需先 setup）：生成一张测试底图
~/.venv-art/bin/python ~/.codebuddy/assets/art-design/comfyui_generate.py \
  --prompt-file <(echo "a calm test gradient, no text") --out /tmp/test.png --workflow zimage --w 512 --h 512
```
全部通过后，**重启 CodeBuddy** 加载技能。

## 7. 排查

- `swift: command not found` → `xcode-select --install`
- 生图 403/401 → 重跑 `setup.sh` 确认 key/URL；ComfyUI 为单 GPU 串行，脚本内置 flock
- 视觉 QA 找不到端点 → 确认 `local_config.json` 的 `llm_endpoints` 或 `~/.codebuddy/models.json`
- GIMP 缺失 → 仅影响分层 PSD / script-fu 路线，其余（compositor/PIL 排版）仍可用
