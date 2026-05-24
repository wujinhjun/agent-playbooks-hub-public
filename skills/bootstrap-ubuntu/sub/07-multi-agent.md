# 07 — Multi-Agent Setup

cc-connect 多 bot + tmux 工作台 + provider 别名，模块化配置。

## Step 1: 问用户要什么

### Agent 选择（多选）

| 选项 | snippet |
|------|---------|
| Claude Code | `agent-claude.toml` |
| Codex | `agent-codex.toml` |
| Gemini | `agent-gemini.toml` |
| Yolo (bypass) | `agent-yolo.toml` |

### Platform 选择（多选）

| 选项 | snippet |
|------|---------|
| 飞书 | `platform-feishu.toml` |
| 钉钉 | `platform-dingtalk.toml` |
| Telegram | `platform-telegram.toml` |
| Slack | `platform-slack.toml` |
| Discord | `platform-discord.toml` |
| 企业微信 | `platform-wecom.toml` |

### Provider 选择（多选）

| 选项 | snippet |
|------|---------|
| Anthropic 官方 | `provider-anthropic.toml` |
| DeepSeek 中转 | `provider-deepseek.toml` |
| Kimi 中转 | `provider-kimi.toml` |

### 其他（多选）

| 选项 | 说明 |
|------|------|
| Hooks 审计日志 | `hooks.toml` |
| tmux 工作台 | `agents-config.sh` |
| provider 别名 | 含在 agents-config.sh 中 |

## Step 2: 组装配置

根据用户选择，拼接 snippets 生成 `config.toml`：

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNIPPETS="$SKILL_DIR/cc-connect"
OUTPUT="./cc-connect-config.toml"

# 1. base
cat "$SNIPPETS/_base.toml" > "$OUTPUT"
echo "" >> "$OUTPUT"

# 2. providers（用户选的）
for p in anthropic deepseek kimi; do
    [[ "${SELECTED_PROVIDERS:-}" == *"$p"* ]] && {
        cat "$SNIPPETS/provider-$p.toml" >> "$OUTPUT"
        echo "" >> "$OUTPUT"
    }
done

# 3. agents × platforms（用户选的 agent 各自配平台）
# 注意：[[projects.platforms]] 是数组元素，每个 agent block 之后紧跟自己选的 platforms
SELECTED_AGENTS="${SELECTED_AGENTS:-claude}"
SELECTED_PLATFORMS="${SELECTED_PLATFORMS:-feishu}"

for agent in $SELECTED_AGENTS; do
    cat "$SNIPPETS/agent-$agent.toml" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    for plat in $SELECTED_PLATFORMS; do
        cat "$SNIPPETS/platform-$plat.toml" >> "$OUTPUT"
        echo "" >> "$OUTPUT"
    done
done

# 4. hooks（如果用户选了）
[[ "${INSTALL_HOOKS:-N}" == "Y" ]] && {
    cat "$SNIPPETS/hooks.toml" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
}

cp "$SNIPPETS/secrets.env.example" ./secrets.env.example
echo "[OK] Generated: $OUTPUT + secrets.env.example"
echo "  Edit placeholders in both files, then re-run this skill to deploy."
```

## Step 3: 部署

用户改完 `cc-connect-config.toml` 和 `secrets.env` 后：

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# secrets
mkdir -p ~/.config/cc-connect && chmod 700 ~/.config/cc-connect
cp ./secrets.env ~/.config/cc-connect/secrets.env
chmod 600 ~/.config/cc-connect/secrets.env

# config
mkdir -p ~/.cc-connect
cp ./cc-connect-config.toml ~/.cc-connect/config.toml

# systemd — 动态解出 node bin 路径（cc-connect 是 npm global 包）
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
NODE_BIN="$(dirname "$(readlink -f "$(command -v node)")")"
[[ -z "$NODE_BIN" ]] && { echo "[FATAL] node not found"; exit 1; }

sed -e "s|REPLACE_ME_USER|$USER|g" \
    -e "s|REPLACE_ME_NODE_BIN|$NODE_BIN|g" \
    "$SKILL_DIR/cc-connect.service" | \
    sudo tee /etc/systemd/system/cc-connect.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable --now cc-connect
sudo systemctl status cc-connect

# 飞书 bot 快速创建（每个 agent 走一遍）
# cc-connect feishu setup --project claude-official
# cc-connect feishu setup --project codex
# ...
```

## Step 4: 飞书后台配置

每个 bot 在飞书开发者后台：
1. 「事件与回调」→ 选**长连接**，订阅 `im.message.receive_v1`
2. 「回调配置」→ 长连接，加 `card.action.trigger`

> 长连接 = 飞书主动连上来，不需要公网 IP/域名/反向代理。

## Step 5: 多 Agent 工作台

```bash
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p ~/.config/agents
cp "$SKILL_DIR/agents-config.sh" ~/.config/agents/agents.sh

rc="$HOME/.bashrc"
[[ "$SHELL" == */zsh ]] && rc="$HOME/.zshrc"
grep -q 'agents.sh' "$rc" 2>/dev/null || echo 'source ~/.config/agents/agents.sh' >> "$rc"
source ~/.config/agents/agents.sh 2>/dev/null || true
```

包含：`cc`/`cck`/`ccd`/`ccy` 别名、`tmux-bootstrap`、`setup-work-dirs`、`docker-sandbox`。

## Step 6: Yolo 安全隔离（如果选了）

```bash
sudo useradd -m -s /bin/bash cc-yolo
# 在 config.toml 里解开 run_as_user = "cc-yolo"
# 验证: cc-connect doctor user-isolation
```
