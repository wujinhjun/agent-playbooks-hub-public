# 02 — Network

## 2.1 Mihomo

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/../bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

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

# 渲染配置 — env 有值的替换，没填的保留 placeholder
cp "$SKILL_DIR/../mihomo-config.yaml" /tmp/mihomo-config.yaml
for v in MIHOMO_VPS_SERVER MIHOMO_VPS_PORT MIHOMO_VPS_PASSWORD MIHOMO_SG_SERVER MIHOMO_SG_PORT MIHOMO_SG_UUID; do
    val="${!v:-}"
    [[ -n "$val" && "$val" != "REPLACE_ME" ]] && sed -i "s|REPLACE_ME_${v#MIHOMO_}|${val}|g" /tmp/mihomo-config.yaml
done

sudo mkdir -p /etc/mihomo/ruleset
sudo cp /tmp/mihomo-config.yaml /etc/mihomo/config.yaml
sudo cp "$SKILL_DIR/../mihomo.service" /etc/systemd/system/mihomo.service
sudo systemctl daemon-reload
sudo systemctl enable mihomo

# 检查是否还有占位符 — 有就不 start
if grep -q REPLACE_ME /etc/mihomo/config.yaml; then
    echo "[WARN] Mihomo config has placeholders — not starting"
    echo "[mihomo] /etc/mihomo/config.yaml 含占位符 — 填完后 systemctl start mihomo" >> "$TODO_FILE"
else
    sudo systemctl start mihomo
    echo "[WARN] TUN mode enabled — SSH may drop!"
fi
echo "[OK] Mihomo installed"
```

## 2.2 Tailscale

仅当 `INSTALL_TAILSCALE=Y` 时执行：

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/../bootstrap.env" 2>/dev/null || true

[[ "${INSTALL_TAILSCALE:-N}" != "Y" ]] && { echo "[SKIP] Tailscale"; exit 0; }

curl -fsSL https://tailscale.com/install.sh | sh
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    sudo tailscale up --authkey "$TAILSCALE_AUTH_KEY" --ssh
    echo "[OK] Tailscale authenticated"
else
    echo "[OK] Tailscale installed — 需手动 sudo tailscale up"
fi
```
