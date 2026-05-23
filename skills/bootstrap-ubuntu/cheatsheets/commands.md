# Agent 命令速查

## Claude Code

| 命令 | provider | IP 守卫 | 说明 |
|------|----------|---------|------|
| `cc "prompt"` | official (OAuth) | ✅ 需要 SG | 日常开发 |
| `cc -y "prompt"` | official | ✅ 需要 SG | bypass 权限 |
| `cc -s -y "prompt"` | official | ✅ 需要 SG | sudo + bypass 一条龙 |
| `ccd "prompt"` | deepseek (API) | ❌ | 不限 IP |
| `ccd -y "prompt"` | deepseek | ❌ | bypass |
| `ccm "prompt"` | minimax (API) | ❌ | 不限 IP |
| `ccm -s -y "prompt"` | minimax | ❌ | sudo + bypass |
| `cc-fallback "prompt"` | 自动降级 | ❌ | deepseek → minimax |

> `claude` 裸命令已被拦截，强制走上面这些。

**官方文档**:
- [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)
- [cc-switch GitHub](https://github.com/anthropics/cc-switch)

## 其他 Agent

| 命令 | Agent | 文档 |
|------|-------|------|
| `cx` | Codex | [OpenAI Codex](https://openai.com/index/introducing-codex) |
| `gm` | Gemini | [Gemini CLI](https://github.com/anthropics/gemini-cli) |
| `ad` | Aider (deepseek) | [Aider](https://aider.chat) |
| `oc` | OpenCode | [OpenCode](https://github.com/anthropics/opencode) |

## IP / 代理

| 命令 | 说明 |
|------|------|
| `check-sg-ip` | 检查当前 IP 是不是 SG 家宽 |
| `curl https://ip.sb` | 直接看出口 IP |
| `sudo systemctl status mihomo` | 代理状态 |
| `sudo journalctl -u mihomo -f` | 代理实时日志 |

**文档**: [mihomo MetaCubeX wiki](https://wiki.metacubex.one) | [Tailscale docs](https://tailscale.com/kb)

## cc-connect（IM 桥接）

| 命令 | 说明 |
|------|------|
| `cc-connect daemon status` | 看状态 |
| `cc-connect daemon logs -f` | 实时日志 |
| `cc-connect daemon logs -n 50` | 最近 50 行 |
| `sudo systemctl restart cc-connect` | 重启（改配置后） |

**文档**: [cc-connect GitHub](https://github.com/anthropics/cc-connect)

## 工具

| 命令 | 说明 | 文档 |
|------|------|------|
| `tmux-bootstrap` | 一键建工作台 | [tmux wiki](https://github.com/tmux/tmux/wiki) |
| `tmux attach -t agents` | 连回工作台 | — |
| `lazygit` | Git TUI | [lazygit](https://github.com/jesseduffield/lazygit) |
| `lazydocker` | Docker TUI | [lazydocker](https://github.com/jesseduffield/lazydocker) |
| `newgrp docker` | docker 权限生效 | [Docker post-install](https://docs.docker.com/engine/install/linux-postinstall) |

## API Key 申请

| Provider | 地址 |
|----------|------|
| DeepSeek | [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys) |
| MiniMax | [platform.minimaxi.com](https://platform.minimaxi.com) |
| Anthropic | [console.anthropic.com](https://console.anthropic.com) |
| GitHub Token | [github.com/settings/tokens](https://github.com/settings/tokens) |
| Tailscale | [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys) |

## 文件位置

| 文件 | 路径 |
|------|------|
| agents config | `~/.config/agents/agents.sh` |
| mihomo config | `/etc/mihomo/config.yaml` |
| cc-connect config | `~/.cc-connect/config.toml` |
| cc-connect secrets | `~/.config/cc-connect/secrets.env` |
| bootstrap skill | `~/workspace/skills/bootstrap-ubuntu/` |
