# 05 — Tools & Services

```bash
#!/bin/bash
set -e
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

# ---- Puppeteer deps ----
if [[ "${INSTALL_PUPPETEER:-N}" == "Y" ]]; then
    # Ubuntu 24.04: libasound2 → libasound2t64
    sudo apt install -y ca-certificates fonts-liberation libasound2t64 libatk-bridge2.0-0 \
        libatk1.0-0 libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 \
        libnss3 libu2f-udev libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 \
        libxkbcommon0 libxrandr2 xdg-utils
    sudo apt install -y libasound2 2>/dev/null || true  # 22.04 fallback
    echo "[OK] Puppeteer deps"
fi

# ---- Docker ----
if [[ "${INSTALL_DOCKER:-N}" == "Y" ]]; then
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$USER"
        sudo systemctl enable --now docker
        echo "[OK] Docker installed"
    else
        echo "[SKIP] Docker already installed"
    fi
fi

# ---- cc-connect (npm 包) ----
if [[ "${INSTALL_CC_CONNECT:-N}" == "Y" ]]; then
    if ! command -v cc-connect &>/dev/null; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
        npm install -g cc-connect
        hash -r 2>/dev/null || true
        echo "[OK] cc-connect: $(command -v cc-connect >/dev/null && cc-connect --version 2>&1 || echo 'installed (re-source shell to use)')"
    else
        echo "[SKIP] cc-connect already installed"
    fi
fi

# ---- codex (npm 包) ----
if [[ "${INSTALL_CODEX:-N}" == "Y" ]] && ! command -v codex &>/dev/null; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    if npm install -g @openai/codex 2>&1; then
        hash -r 2>/dev/null || true
        echo "[OK] codex installed"
    else
        echo "[codex] Install failed" >> "$TODO_FILE"
    fi
fi
```
