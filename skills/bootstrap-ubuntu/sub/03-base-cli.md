# 03 — Base CLI

```bash
#!/bin/bash
set -e
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

# ---- tmux ----
if [[ "${INSTALL_TMUX:-N}" == "Y" ]]; then
    sudo apt install -y tmux
    echo "[OK] tmux"
fi

# ---- rg / fd / fzf / jq ----
if [[ "${INSTALL_CLI:-N}" == "Y" ]]; then
    sudo apt install -y jq ripgrep fzf
    # fd (22.04: fd-find, 24.04: fd)
    if ! command -v fd &>/dev/null; then
        sudo apt install -y fd-find 2>/dev/null || sudo apt install -y fd 2>/dev/null
        command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && \
            sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi
    echo "[OK] CLI tools (rg fd fzf jq)"
fi

# ---- Git + gh ----
if [[ "${INSTALL_GIT:-N}" == "Y" ]]; then
    sudo apt install -y git

    if ! command -v gh &>/dev/null; then
        (type -p wget >/dev/null || sudo apt install -y wget)
        sudo mkdir -p -m 755 /etc/apt/keyrings
        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
            sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
            sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update -qq
        sudo apt install -y gh
    fi

    # git 全局配置
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"
    git config --global pull.rebase true
    git config --global init.defaultBranch main

    # SSH key
    if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f ~/.ssh/id_ed25519 -N "" -q
        echo "[OK] SSH key generated: ~/.ssh/id_ed25519"
    else
        echo "[SKIP] SSH key already exists"
    fi
    eval "$(ssh-agent -s)" 2>/dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null || true

    # gh auth + 上传 SSH key
    if [[ -n "${GITHUB_TOKEN:-}" ]]; then
        echo "$GITHUB_TOKEN" | gh auth login --with-token
        echo "[OK] gh authenticated"

        pub_fp=$(awk '{print $2}' ~/.ssh/id_ed25519.pub)
        if ! gh ssh-key list 2>/dev/null | grep -q "$pub_fp"; then
            gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)" 2>/dev/null && \
                echo "[OK] SSH key uploaded to GitHub" || \
                echo "[TODO] SSH key upload failed — cat ~/.ssh/id_ed25519.pub → https://github.com/settings/keys" >> "$TODO_FILE"
        else
            echo "[SKIP] SSH key already on GitHub"
        fi
        git config --global url."git@github.com:".insteadOf "https://github.com/"
    else
        echo "[TODO] GITHUB_TOKEN 未设置 — 手动上传 SSH key: https://github.com/settings/keys" >> "$TODO_FILE"
    fi
    echo "[OK] Git + gh configured"
fi
```
