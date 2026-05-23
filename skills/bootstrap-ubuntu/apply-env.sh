#!/bin/bash
# ==========================================================================
# apply-env — 填好 bootstrap.env 后运行此脚本，将配置注入各组件
# 用法: source bootstrap.env && bash apply-env.sh
# ==========================================================================
set -e
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f "$SKILL_DIR/bootstrap.env" ]]; then
    echo "[FATAL] bootstrap.env not found. Create it first:"
    echo "  cp $SKILL_DIR/bootstrap.env.example $SKILL_DIR/bootstrap.env"
    exit 1
fi
source "$SKILL_DIR/bootstrap.env"
echo "[OK] Loaded bootstrap.env"

# ---- Mihomo config ----
if [[ -n "${MIHOMO_VPS_SERVER:-}" ]]; then
    echo "-- Rendering mihomo config --"
    sed -e "s|REPLACE_ME_VPS_SERVER|${MIHOMO_VPS_SERVER}|g" \
        -e "s|REPLACE_ME_VPS_PORT|${MIHOMO_VPS_PORT:-443}|g" \
        -e "s|REPLACE_ME_VPS_PASSWORD|${MIHOMO_VPS_PASSWORD}|g" \
        -e "s|REPLACE_ME_SG_SERVER|${MIHOMO_SG_SERVER:-sg.example.com}|g" \
        -e "s|REPLACE_ME_SG_PORT|${MIHOMO_SG_PORT:-443}|g" \
        -e "s|REPLACE_ME_SG_UUID|${MIHOMO_SG_UUID}|g" \
        "$SKILL_DIR/mihomo-config.yaml" | sudo tee /etc/mihomo/config.yaml > /dev/null
    sudo systemctl restart mihomo 2>/dev/null || sudo systemctl start mihomo
    echo "[OK] Mihomo config applied"
else
    echo "[SKIP] Mihomo — MIHOMO_VPS_SERVER not set"
fi

# ---- Git identity ----
if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" ]]; then
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    echo "[OK] Git: $GIT_USER_NAME <$GIT_USER_EMAIL>"

    # SSH key
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

# ---- GitHub CLI + SSH key upload ----
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null && \
        echo "[OK] gh authenticated" || echo "[FAIL] gh auth"
    # 上传 SSH key
    if [[ -f ~/.ssh/id_ed25519.pub ]]; then
        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)" 2>/dev/null && \
            echo "[OK] SSH key uploaded to GitHub" || echo "[SKIP] SSH key already uploaded or upload failed"
    fi
    git config --global url."git@github.com:".insteadOf "https://github.com/" 2>/dev/null || true
else
    echo "[SKIP] gh — GITHUB_TOKEN not set"
fi

# ---- Tailscale ----
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --ssh 2>/dev/null && \
        echo "[OK] Tailscale authenticated" || echo "[FAIL] tailscale up"
else
    echo "[SKIP] Tailscale — TAILSCALE_AUTH_KEY not set"
fi

# ---- cc-connect ----
if [[ -n "${CC_CONNECT_TOKEN:-}" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    cc-connect --token "$CC_CONNECT_TOKEN" &
    echo "[OK] cc-connect started (PID $!)"
else
    echo "[SKIP] cc-connect — CC_CONNECT_TOKEN not set"
fi

echo ""
echo "===== Done ====="
echo "剩余 TODO 检查:"
grep -c REPLACE_ME /etc/mihomo/config.yaml 2>/dev/null && \
    echo "  [!] mihomo config 仍有占位符" || \
    echo "  [OK] mihomo config 无占位符"
git config --global user.name &>/dev/null && echo "  [OK] git identity" || echo "  [!] git identity 未配"
gh auth status &>/dev/null 2>&1 && echo "  [OK] gh auth" || echo "  [!] gh 未登录"
tailscale status &>/dev/null 2>&1 && echo "  [OK] Tailscale" || echo "  [!] Tailscale 未登录"
