---
name: bootstrap-ubuntu
public: true
description: 初始化 Ubuntu 开发环境。当用户说"bootstrap""初始化服务器""配置开发机""装环境""setup server"时触发。交互式模块选择，渐进式安装 Node.js/Go/Python/Docker/mihomo/cc-connect 等，不装不需要的东西。
---

# Bootstrap Ubuntu

你是一个 Ubuntu 开发环境初始化助手。按以下流程执行，**只安装用户勾选的模块**。

## 配置约定

隐私配置（API key、密码等）从 `~/.config/bootstrap-ubuntu/` 读取，该目录由用户自行维护，不随 skill 分发。

```
~/.config/bootstrap-ubuntu/       # 用户私有（不提交）
├── bootstrap.env                 # API key / token / 密码
├── mihomo-config.yaml            # 代理配置（含服务器地址）
└── cc-connect-config.toml        # IM 桥接配置

<skill-dir>/templates/            # 公开模板
├── bootstrap.env.example
├── mihomo-config.yaml.example
└── cc-connect-config.toml.example
```

执行前检查：私有配置存在则 source/使用，不存在则用模板（占位符保留，最后生成 TODO 提醒）。

## 流程

### 1. 模块选择

用 AskUserQuestion 一次性展示所有模块让用户勾选（多选）。

```
基础环境:
  [ ] 镜像源 (Ubuntu mirrors)
  [ ] Git + GitHub CLI
  [ ] rg + fd + fzf + jq
  [ ] tmux

网络:
  [ ] Mihomo 代理 (需填服务器配置)
  [ ] Tailscale (需 Auth Key)

运行时:
  [ ] Node.js (nvm)
  [ ] Go
  [ ] Python (miniconda + uv)
  [ ] Java (sdkman)
  [ ] Rust (rustup)
  [ ] Flutter (fvm)

工具:
  [ ] Docker
  [ ] Puppeteer
  [ ] cc-connect (IM 桥接)
  [ ] Codex

美化:
  [ ] zsh + starship
  [ ] chezmoi
  [ ] lazygit + lazydocker

多 Agent:
  [ ] cc-connect 多 bot
  [ ] tmux 工作台 (tmux-bootstrap)
  [ ] provider 别名 (cc/ccd/ccm)
  [ ] Docker 沙箱
```

### 2. 收集配置

对勾选的模块，逐项问用户是否现在填写配置。选"否"则保留占位符，最后 TODO 提醒。

| 勾选 | 需要收集 |
|------|---------|
| Mihomo | 服务器地址/端口/密码/UUID |
| Tailscale | Auth Key |
| Git + gh | 用户名/邮箱/GitHub Token |
| cc-connect | Token + IM App 凭证 |

用户填写的值写入 `~/.config/bootstrap-ubuntu/bootstrap.env`。

### 3. 执行安装

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TODO_FILE="/tmp/bootstrap-todos.txt"
> "$TODO_FILE"

# 加载私有配置
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
[[ -f "$PRIV_DIR/bootstrap.env" ]] && source "$PRIV_DIR/bootstrap.env"

# 预装
sudo apt update -qq
sudo apt install -y build-essential zip unzip curl wget ca-certificates
```

按勾选执行 sub/ 文件，每个模块幂等（`command -v` / `[[ -d ]]` 检查），失败记 TODO 继续。

| 模块 | 文件 |
|------|------|
| 镜像源 | [sub/01-mirrors.md](sub/01-mirrors.md) |
| Mihomo / Tailscale | [sub/02-network.md](sub/02-network.md) |
| Git / CLI 工具 / tmux | [sub/03-base-cli.md](sub/03-base-cli.md) |
| Node / Go / Python / Java / Rust / Flutter | [sub/04-runtimes.md](sub/04-runtimes.md) |
| Docker / Puppeteer / cc-connect / Codex | [sub/05-tools.md](sub/05-tools.md) |
| zsh / starship / chezmoi / lazygit | [sub/06-nice-to-have.md](sub/06-nice-to-have.md) |
| 多 Agent 全部 | [sub/07-multi-agent.md](sub/07-multi-agent.md) |

### 4. 生成报告

输出安装总结到 `agent-log/BOOTSTRAP-REPORT.md`，列出已安装模块和待处理 TODO。

## 全局约束

- 使用 `set -e`，不用 `set -u`（Claude Code snapshot 引用非绑定变量会 crash）
- 每装完运行时立即 source rc（nvm/gvm/sdkman/rustup 后续步骤依赖）
- 失败不阻塞，记 TODO，继续
- 幂等检查：`command -v` 或 `[[ -d ]]`，重跑安全
- **只装勾选的模块**，未勾选的绝对不碰
- 私有配置优先于模板：`[[ -f "$PRIV_DIR/x" ]] && use "$PRIV_DIR/x" || use template`

## 参考文档

### 内部速查表
- [cheatsheets/commands.md](cheatsheets/commands.md) — Agent 命令、代理、文件位置
- [cheatsheets/tmux.md](cheatsheets/tmux.md) — Tmux 快捷键

### 外部文档
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- [cc-switch](https://github.com/anthropics/cc-switch)
- [cc-connect](https://github.com/anthropics/cc-connect)
- [mihomo](https://wiki.metacubex.one)
- [Tailscale](https://tailscale.com/kb)
- [Docker](https://docs.docker.com/engine/install/ubuntu)
- [nvm](https://github.com/nvm-sh/nvm) | [uv](https://docs.astral.sh/uv) | [rustup](https://rustup.rs) | [Go](https://go.dev/dl)

### API Key 申请
- [DeepSeek](https://platform.deepseek.com/api_keys) | [MiniMax](https://platform.minimaxi.com) | [Anthropic](https://console.anthropic.com)
- [GitHub Token](https://github.com/settings/tokens) | [Tailscale](https://login.tailscale.com/admin/settings/keys)
