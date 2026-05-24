# 00 — Pre-flight

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"
> "$TODO_FILE"

# Seed 私有配置目录
mkdir -p "$PRIV_DIR"
[[ ! -f "$PRIV_DIR/bootstrap.env" ]] && \
    cp "$SKILL_DIR/templates/bootstrap.env.example" "$PRIV_DIR/bootstrap.env" && \
    echo "[OK] Seeded $PRIV_DIR/bootstrap.env (请填值后重跑)"
[[ ! -f "$PRIV_DIR/mihomo-config.yaml" ]] && \
    cp "$SKILL_DIR/templates/mihomo-config.yaml.example" "$PRIV_DIR/mihomo-config.yaml"

source "$PRIV_DIR/bootstrap.env"

UBUNTU_VERSION=$(lsb_release -rs)
echo "[INFO] Ubuntu $UBUNTU_VERSION detected"

# 预装后续 phase 需要的底层依赖
sudo apt update -qq
sudo apt install -y build-essential zip unzip curl wget ca-certificates bison
echo "[OK] Build deps installed"

# 确认 NOPASSWD sudo —— 高权限变更，先确认用户同意再配
if ! sudo -n true 2>/dev/null; then
    echo "[WARN] NOPASSWD sudo 未配置。"
    echo '  如确认要启用（共享机器请慎用），执行:'
    echo '    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/claude-agent'
    echo "[preflight] NOPASSWD sudo 未启用 — 部分模块会反复要密码" >> "$TODO_FILE"
fi

# Git 身份只在用户勾了 INSTALL_GIT 时才强校验
if [[ "${INSTALL_GIT:-N}" == "Y" ]]; then
    if [[ -z "${GIT_USER_NAME:-}" || -z "${GIT_USER_EMAIL:-}" ]]; then
        echo "[FATAL] INSTALL_GIT=Y 但 GIT_USER_NAME/EMAIL 未填"
        echo "  编辑 $PRIV_DIR/bootstrap.env 后重跑"
        exit 1
    fi
    echo "[OK] Git identity: $GIT_USER_NAME <$GIT_USER_EMAIL>"
fi

# 审计可选 env 缺失（不阻塞，记 TODO）
[[ "${INSTALL_GIT:-N}" == "Y" && -z "${GITHUB_TOKEN:-}" ]] && \
    echo "[gh] GITHUB_TOKEN 未填 — 需手动 gh auth login" >> "$TODO_FILE"

if [[ "${INSTALL_MIHOMO:-N}" == "Y" ]] && [[ -f "$PRIV_DIR/mihomo-config.yaml" ]]; then
    if grep -qE 'YOUR_(SERVER|UUID|REALITY_)' "$PRIV_DIR/mihomo-config.yaml"; then
        echo "[mihomo] $PRIV_DIR/mihomo-config.yaml 仍是示例 — 编辑后 02-network 才会启动" >> "$TODO_FILE"
    fi
fi

[[ "${INSTALL_TAILSCALE:-N}" == "Y" && -z "${TAILSCALE_AUTH_KEY:-}" ]] && \
    echo "[tailscale] TAILSCALE_AUTH_KEY 未填 — 需手动 sudo tailscale up" >> "$TODO_FILE"

[[ "${INSTALL_CC_CONNECT:-N}" == "Y" && -z "${CC_CONNECT_TOKEN:-}" ]] && \
    echo "[cc-connect] CC_CONNECT_TOKEN 未填 — 需手动配置" >> "$TODO_FILE"

echo "[OK] Pre-flight complete"
```
