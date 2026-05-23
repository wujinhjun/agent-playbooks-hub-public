# 06 — Nice-to-have

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/../bootstrap.env" 2>/dev/null || true

# ---- zsh + starship ----
if [[ "${INSTALL_ZSH:-Y}" == "Y" ]]; then
    sudo apt install -y zsh
    if ! command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin
    fi
    if ! grep -q 'starship init zsh' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi
    # 迁移 bash 历史和 PATH 到 zsh
    cp ~/.bash_history ~/.zsh_history_pre 2>/dev/null || true
    cat >> ~/.zshrc <<'ZSHRCEOF'

# === 从 bash 迁移的 runtime 环境 ===
export PATH="$HOME/.local/bin:/usr/local/go/bin:$HOME/.cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && \. "$HOME/.sdkman/bin/sdkman-init.sh"
ZSHRCEOF
    echo "[OK] zsh + starship + bash migrated"

# 部署 agents-config 到正确的 shell
mkdir -p ~/.config/agents
cp "$SKILL_DIR/../agents-config.sh" ~/.config/agents/agents.sh
if [[ "$SHELL" == */zsh ]]; then
    grep -q 'agents.sh' ~/.zshrc 2>/dev/null || echo "source ~/.config/agents/agents.sh" >> ~/.zshrc
elif [[ "$SHELL" == */bash ]]; then
    grep -q 'agents.sh' ~/.bashrc 2>/dev/null || echo "source ~/.config/agents/agents.sh" >> ~/.bashrc
fi
echo "[OK] agents-config deployed to $(basename $SHELL)"
fi

# ---- chezmoi ----
if [[ "${INSTALL_CHEZMOI:-Y}" == "Y" ]] && ! command -v chezmoi &>/dev/null; then
    sudo snap install chezmoi --classic 2>/dev/null || \
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
    echo "[OK] chezmoi"
fi

# ---- lazygit + lazydocker ----
if [[ "${INSTALL_LAZY:-Y}" == "Y" ]]; then
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

# ---- systemd lingering ----
sudo loginctl enable-linger "$USER"
echo "[OK] Systemd user lingering enabled"
```
