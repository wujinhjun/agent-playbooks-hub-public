# 06 — Nice-to-have

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true

# ---- zsh + starship ----
if [[ "${INSTALL_ZSH:-N}" == "Y" ]]; then
    sudo apt install -y zsh
    if ! command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
    fi
    if ! grep -q 'starship init zsh' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi
    # 迁移 bash 历史和 runtime PATH 到 zsh
    cp ~/.bash_history ~/.zsh_history_pre 2>/dev/null || true
    if ! grep -q '从 bash 迁移的 runtime 环境' ~/.zshrc 2>/dev/null; then
        cat >> ~/.zshrc <<'ZSHRCEOF'

# === 从 bash 迁移的 runtime 环境 ===
export PATH="$HOME/.local/bin:/usr/local/go/bin:$HOME/.cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && \. "$HOME/.sdkman/bin/sdkman-init.sh"
ZSHRCEOF
    fi
    echo "[OK] zsh + starship"
fi

# ---- agents-config 部署 ----
if [[ "${INSTALL_MULTI_AGENT:-N}" == "Y" ]]; then
    mkdir -p ~/.config/agents
    cp "$SKILL_DIR/agents-config.sh" ~/.config/agents/agents.sh
    rc="$HOME/.bashrc"
    [[ "$SHELL" == */zsh ]] && rc="$HOME/.zshrc"
    grep -q 'agents.sh' "$rc" 2>/dev/null || echo "source ~/.config/agents/agents.sh" >> "$rc"
    echo "[OK] agents-config deployed to $(basename "$rc")"
fi

# ---- chezmoi ----
if [[ "${INSTALL_CHEZMOI:-N}" == "Y" ]] && ! command -v chezmoi &>/dev/null; then
    sudo snap install chezmoi --classic 2>/dev/null || \
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
    echo "[OK] chezmoi"
fi

# ---- lazygit + lazydocker ----
if [[ "${INSTALL_LAZY:-N}" == "Y" ]]; then
    if ! command -v lazygit &>/dev/null; then
        LAZYGIT_VER=$(curl -sL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r .tag_name | sed 's/v//')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VER}/lazygit_${LAZYGIT_VER}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo mv /tmp/lazygit /usr/local/bin/lazygit
        echo "[OK] lazygit"
    fi
    if ! command -v lazydocker &>/dev/null; then
        LAZYDOCKER_VER=$(curl -sL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | jq -r .tag_name | sed 's/v//')
        curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/v${LAZYDOCKER_VER}/lazydocker_${LAZYDOCKER_VER}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
        sudo mv /tmp/lazydocker /usr/local/bin/lazydocker
        echo "[OK] lazydocker"
    fi
fi

# ---- systemd lingering（多 agent / cc-connect 长期运行需要）----
if [[ "${INSTALL_MULTI_AGENT:-N}" == "Y" || "${INSTALL_CC_CONNECT:-N}" == "Y" ]]; then
    sudo loginctl enable-linger "$USER"
    echo "[OK] systemd user lingering enabled"
fi
```
