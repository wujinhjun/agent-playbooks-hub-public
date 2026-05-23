# 00 — Pre-flight

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/../bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

UBUNTU_VERSION=$(lsb_release -rs)
echo "[INFO] Ubuntu $UBUNTU_VERSION detected"

# 预装后续 phase 需要的底层依赖
sudo apt update -qq
sudo apt install -y build-essential zip unzip curl wget ca-certificates bison
echo "[OK] Build deps installed"

# 确认 NOPASSWD sudo
if ! sudo -n true 2>/dev/null; then
    echo "[FATAL] NOPASSWD sudo not configured."
    echo '  Run: echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/claude-agent'
    exit 1
fi
echo "[OK] NOPASSWD sudo configured"

# 校验 git 身份
if [[ -z "${GIT_USER_NAME:-}" || -z "${GIT_USER_EMAIL:-}" ]]; then
    echo "[FATAL] GIT_USER_NAME and GIT_USER_EMAIL must be set in bootstrap.env"
    exit 1
fi
echo "[OK] Git identity: $GIT_USER_NAME <$GIT_USER_EMAIL>"

# 审计 env 缺失项（不阻塞）
if [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "[gh] GITHUB_TOKEN 未填写 — 需手动 gh auth login" >> "$TODO_FILE"
fi
if [[ -z "${MIHOMO_VPS_SERVER:-}" ]]; then
    echo "[mihomo] MIHOMO_VPS_SERVER 未填写 — config 将保留占位符" >> "$TODO_FILE"
fi
if [[ -z "${MIHOMO_VPS_PASSWORD:-}" || "${MIHOMO_VPS_PASSWORD}" == "REPLACE_ME" ]]; then
    echo "[mihomo] MIHOMO_VPS_PASSWORD 仍是占位符 — 需编辑 /etc/mihomo/config.yaml" >> "$TODO_FILE"
fi
if [[ -z "${MIHOMO_SG_UUID:-}" || "${MIHOMO_SG_UUID}" == "REPLACE_ME" ]]; then
    echo "[mihomo] MIHOMO_SG_UUID 仍是占位符 — 需编辑 /etc/mihomo/config.yaml" >> "$TODO_FILE"
fi
if [[ -z "${TAILSCALE_AUTH_KEY:-}" ]]; then
    echo "[tailscale] TAILSCALE_AUTH_KEY 未填写 — 需手动 sudo tailscale up" >> "$TODO_FILE"
fi
if [[ -z "${CC_CONNECT_TOKEN:-}" ]]; then
    echo "[cc-connect] CC_CONNECT_TOKEN 未填写 — 需手动配置" >> "$TODO_FILE"
fi

echo "[OK] Pre-flight complete"
```
