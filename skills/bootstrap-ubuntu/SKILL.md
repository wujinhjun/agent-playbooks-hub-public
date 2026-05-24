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
└── mihomo-config.yaml            # 代理配置（含服务器地址）

<skill-dir>/templates/            # 公开模板
├── bootstrap.env.example
└── mihomo-config.yaml.example
```

**Seed 流程**（pre-flight 执行）：

```bash
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
mkdir -p "$PRIV_DIR"
[[ ! -f "$PRIV_DIR/bootstrap.env" ]] && \
    cp "$SKILL_DIR/templates/bootstrap.env.example" "$PRIV_DIR/bootstrap.env"
[[ ! -f "$PRIV_DIR/mihomo-config.yaml" ]] && \
    cp "$SKILL_DIR/templates/mihomo-config.yaml.example" "$PRIV_DIR/mihomo-config.yaml"
```

所有 sub 脚本都 `source "$PRIV_DIR/bootstrap.env"`，绝不读 skill 目录里的 env。

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

### 2. 收集配置 + 生成 env

把 Step 1 勾选项映射成 `INSTALL_*` 变量，连同用户填的凭证一起，**追加写入** `~/.config/bootstrap-ubuntu/bootstrap.env`（已存在的 key 用 sed 替换，不重复 append）。

| 勾选项 | 对应 INSTALL_ 变量 | 需要额外收集 |
|------|------|---------|
| 镜像源 | `INSTALL_MIRRORS=Y` | — |
| Git + gh | `INSTALL_GIT=Y` | `GIT_USER_NAME` / `GIT_USER_EMAIL` / `GITHUB_TOKEN` |
| rg+fd+fzf+jq | `INSTALL_CLI=Y` | — |
| tmux | `INSTALL_TMUX=Y` | — |
| Mihomo | `INSTALL_MIHOMO=Y` | 用户自行编辑 `~/.config/bootstrap-ubuntu/mihomo-config.yaml`（任何 mihomo 协议） |
| Tailscale | `INSTALL_TAILSCALE=Y` | `TAILSCALE_AUTH_KEY` |
| Node | `INSTALL_NODE=Y` | — |
| Go | `INSTALL_GO=Y` | — |
| Python | `INSTALL_PYTHON=Y` | — |
| Java | `INSTALL_JAVA=Y` | — |
| Rust | `INSTALL_RUST=Y` | — |
| Flutter | `INSTALL_FLUTTER=Y` | — |
| Docker | `INSTALL_DOCKER=Y` | — |
| Puppeteer | `INSTALL_PUPPETEER=Y` | — |
| cc-connect | `INSTALL_CC_CONNECT=Y` | `CC_CONNECT_TOKEN`（可选） |
| Codex | `INSTALL_CODEX=Y` | — |
| zsh+starship | `INSTALL_ZSH=Y` | — |
| chezmoi | `INSTALL_CHEZMOI=Y` | — |
| lazygit+lazydocker | `INSTALL_LAZY=Y` | — |
| 多 Agent | `INSTALL_MULTI_AGENT=Y` | — |

**默认行为：未勾选的模块 `INSTALL_X=N`，sub 脚本通过 `[[ "${INSTALL_X:-N}" == "Y" ]]` 守卫**。

#### 实施细节：把答案 upsert 到 bootstrap.env

bash function（推荐放到本 sub 顶部或 inline 用）：

```bash
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
ENV_FILE="$PRIV_DIR/bootstrap.env"

# 已有 key 就替换，没有就 append。值里有 " / & / | 时也安全。
upsert_env() {
    local key="$1" val="$2"
    # 用 python 做替换，避免 sed 转义地狱
    python3 - "$key" "$val" "$ENV_FILE" <<'PY'
import sys, pathlib, re
key, val, path = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
val_q = '"' + val.replace('\\', '\\\\').replace('"', '\\"') + '"'
lines = path.read_text().splitlines() if path.exists() else []
pat = re.compile(rf'^\s*#?\s*{re.escape(key)}\s*=')
hit = False
for i, ln in enumerate(lines):
    if pat.match(ln):
        lines[i] = f'{key}={val_q}'
        hit = True
        break
if not hit:
    lines.append(f'{key}={val_q}')
path.write_text('\n'.join(lines) + '\n')
PY
}
```

**Claude 的执行步骤**：

1. 调 AskUserQuestion 拿到勾选列表 → 内存里转成 `SELECTED=(MIRRORS GIT NODE ...)`
2. 对完整模块清单逐项写：`upsert_env "INSTALL_X" "Y"` 或 `"N"`
3. 对需要凭证的模块（Git/GitHub/Tailscale/cc-connect），用第二轮 AskUserQuestion 收集，同样走 `upsert_env`
4. 写完后 `chmod 600 "$ENV_FILE"` 一次
5. Mihomo 单独提醒用户："请编辑 `~/.config/bootstrap-ubuntu/mihomo-config.yaml` 后再继续"，**不要尝试通过 env 替换字段**

### 3. 执行安装

每个 sub 文件按顺序执行（脚本内部根据 `INSTALL_*` gate 决定是否真正干活）。统一约定：

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"
[[ -f "$PRIV_DIR/bootstrap.env" ]] && source "$PRIV_DIR/bootstrap.env"
```

每个模块幂等（`command -v` / `[[ -d ]]` 检查），失败记 TODO 继续。

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
- **只装勾选的模块**：每个 sub 块开头都用 `[[ "${INSTALL_X:-N}" == "Y" ]] || { echo "[SKIP] X"; ... }` 守卫
- 私有配置只在 `~/.config/bootstrap-ubuntu/`，绝不在 skill 目录里读写 env / 真实凭证
- **NOPASSWD sudo 是高权限变更**，配置前应向用户确认（共享环境/有他人访问的机器**不要启用**）
- **Mihomo TUN 模式会改路由表**，远程 SSH 启动时可能掉线：启动前提示用户准备 console/Tailscale 兜底

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
