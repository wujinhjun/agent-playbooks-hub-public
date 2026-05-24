# 02 — Network

## 2.1 Mihomo

此 sub 不修改 mihomo config，**只把 `~/.config/bootstrap-ubuntu/mihomo-config.yaml`
原样拷到 `/etc/mihomo/config.yaml`**。任何 mihomo 支持的协议都可以——用户自己写那个文件。

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

[[ "${INSTALL_MIHOMO:-N}" != "Y" ]] && { echo "[SKIP] mihomo"; exit 0; }

# ---- 装二进制 ----
MIHOMO_VER=$(curl -sL --connect-timeout 10 https://api.github.com/repos/MetaCubeX/mihomo/releases/latest | jq -r .tag_name)
if [[ -z "$MIHOMO_VER" || "$MIHOMO_VER" == "null" ]]; then
    echo "[FATAL] Cannot fetch mihomo version — GitHub API unreachable"
    exit 1
fi
curl -sL --connect-timeout 60 -o /tmp/mihomo.gz \
    "https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VER}/mihomo-linux-amd64-${MIHOMO_VER}.gz"
gunzip -f /tmp/mihomo.gz
sudo mv /tmp/mihomo /usr/local/bin/mihomo
sudo chmod +x /usr/local/bin/mihomo

# ---- 部署 config ----
SRC="$PRIV_DIR/mihomo-config.yaml"
if [[ ! -f "$SRC" ]]; then
    cp "$SKILL_DIR/templates/mihomo-config.yaml.example" "$SRC"
    echo "[WARN] $SRC 是示例 — 编辑成真值后重跑"
    echo "[mihomo] $SRC 仍是示例 — 填完后 systemctl start mihomo" >> "$TODO_FILE"
    exit 0
fi

sudo mkdir -p /etc/mihomo/ruleset
sudo cp "$SRC" /etc/mihomo/config.yaml
sudo cp "$SKILL_DIR/mihomo.service" /etc/systemd/system/mihomo.service
sudo systemctl daemon-reload
sudo systemctl enable mihomo

# ---- 启动前校验：仍含示例占位符就不启 ----
if grep -qE 'YOUR_(SERVER|UUID|REALITY_)' /etc/mihomo/config.yaml; then
    echo "[WARN] mihomo config 仍含示例占位符 YOUR_* — 不启动"
    echo "[mihomo] /etc/mihomo/config.yaml 含示例占位符 — 改完后 systemctl start mihomo" >> "$TODO_FILE"
else
    if grep -q "tun:\s*$" /etc/mihomo/config.yaml || grep -qE 'enable:\s*true' /etc/mihomo/config.yaml; then
        echo "[WARN] mihomo config 看起来开启了 TUN——会改路由表，远程 SSH 可能掉线。"
        echo "       如无 console/Tailscale 兜底，按 Ctrl-C 取消，关掉 tun.enable 再跑"
        sleep 5
    fi
    sudo systemctl start mihomo
fi
echo "[OK] Mihomo installed"
```

## 2.2 Tailscale

```bash
#!/bin/bash
set -e
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true

[[ "${INSTALL_TAILSCALE:-N}" != "Y" ]] && { echo "[SKIP] Tailscale"; exit 0; }

curl -fsSL https://tailscale.com/install.sh | sh
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --ssh
    echo "[OK] Tailscale authenticated"
else
    echo "[OK] Tailscale installed — 需手动 sudo tailscale up"
fi
```
