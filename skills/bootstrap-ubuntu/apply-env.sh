#!/bin/bash
# ==========================================================================
# apply-env — 改完 ~/.config/bootstrap-ubuntu/bootstrap.env 后重新应用配置
# 不重装组件，只把 env 里的值刷新到 mihomo / git / gh / tailscale / cc-connect
# 用法: bash apply-env.sh
# ==========================================================================
set -e
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"

if [[ ! -f "$PRIV_DIR/bootstrap.env" ]]; then
    echo "[FATAL] $PRIV_DIR/bootstrap.env not found."
    echo "  先运行 skill 的 pre-flight 让它自动 seed，或手动复制:"
    echo "    mkdir -p $PRIV_DIR"
    echo "    cp $SKILL_DIR/templates/bootstrap.env.example $PRIV_DIR/bootstrap.env"
    exit 1
fi
source "$PRIV_DIR/bootstrap.env"
echo "[OK] Loaded $PRIV_DIR/bootstrap.env"

# ---- Mihomo config 重新部署 ----
SRC="$PRIV_DIR/mihomo-config.yaml"
if [[ -f "$SRC" ]] && ! grep -qE 'YOUR_(SERVER|UUID|REALITY_)' "$SRC"; then
    sudo cp "$SRC" /etc/mihomo/config.yaml
    sudo systemctl restart mihomo 2>/dev/null || sudo systemctl start mihomo 2>/dev/null || \
        echo "[WARN] mihomo systemd unit 不存在 — 先跑 02-network sub"
    echo "[OK] Mihomo config redeployed from $SRC"
else
    echo "[SKIP] Mihomo — $SRC 不存在或仍含示例占位符"
fi

# ---- Git identity ----
if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo "[OK] Git: $GIT_USER_NAME <$GIT_USER_EMAIL>"

    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f ~/.ssh/id_ed25519 -N "" -q
        echo "[OK] SSH key generated"
    fi
    eval "$(ssh-agent -s)" 2>/dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true
else
    echo "[SKIP] Git — GIT_USER_NAME or GIT_USER_EMAIL not set"
fi

# ---- GitHub CLI + SSH key 上传 ----
if [[ -n "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null && \
        echo "[OK] gh authenticated" || echo "[FAIL] gh auth"
    if [[ -f ~/.ssh/id_ed25519.pub ]]; then
        pub_fp=$(awk '{print $2}' ~/.ssh/id_ed25519.pub)
        if ! gh ssh-key list 2>/dev/null | grep -q "$pub_fp"; then
            gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)" 2>/dev/null && \
                echo "[OK] SSH key uploaded to GitHub" || echo "[SKIP] SSH key upload failed"
        fi
    fi
    git config --global url."git@github.com:".insteadOf "https://github.com/" 2>/dev/null || true
else
    echo "[SKIP] gh — GITHUB_TOKEN not set or gh not installed"
fi

# ---- Tailscale ----
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]] && command -v tailscale &>/dev/null; then
    sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --ssh && \
        echo "[OK] Tailscale authenticated" || echo "[FAIL] tailscale up"
else
    echo "[SKIP] Tailscale — TAILSCALE_AUTH_KEY not set or tailscale not installed"
fi

# ---- cc-connect 状态检查 ----
if [[ -n "${CC_CONNECT_TOKEN:-}" ]] && command -v cc-connect &>/dev/null; then
    if systemctl is-active --quiet cc-connect; then
        echo "[OK] cc-connect already running via systemd"
    else
        echo "[WARN] cc-connect 未通过 systemd 跑 — 走 07-multi-agent 部署"
    fi
else
    echo "[SKIP] cc-connect — token not set or binary missing"
fi

echo ""
echo "===== Done ====="
[[ -f /etc/mihomo/config.yaml ]] && {
    grep -qE 'YOUR_(SERVER|UUID|REALITY_)' /etc/mihomo/config.yaml && \
        echo "  [!] mihomo config 仍是示例占位符" || echo "  [OK] mihomo config 无示例占位符"
}
git config --global user.name &>/dev/null && echo "  [OK] git identity" || echo "  [!] git identity 未配"
gh auth status &>/dev/null 2>&1 && echo "  [OK] gh auth" || echo "  [!] gh 未登录"
tailscale status &>/dev/null 2>&1 && echo "  [OK] Tailscale" || echo "  [!] Tailscale 未登录"
