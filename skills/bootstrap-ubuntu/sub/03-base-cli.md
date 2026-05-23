# 03 — Base CLI

```bash
#!/bin/bash
set -e
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SKILL_DIR/../bootstrap.env" 2>/dev/null || true
TODO_FILE="${TODO_FILE:-/tmp/bootstrap-todos.txt}"

sudo apt install -y tmux git jq

# gh (GitHub CLI)
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
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    echo "[OK] gh authenticated"
else
    echo "[gh] 已安装 — 需手动 gh auth login" >> "$TODO_FILE"
fi

# ripgrep
sudo apt install -y ripgrep

# fd (22.04: fd-find, 24.04: fd)
if ! command -v fd &>/dev/null; then
    sudo apt install -y fd-find 2>/dev/null || sudo apt install -y fd 2>/dev/null
    command -v fdfind &>/dev/null && ! command -v fd &>/dev/null && \
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi

# fzf
sudo apt install -y fzf

# git 全局配置
git config --global user.name "${GIT_USER_NAME:-}" 2>/dev/null || true
git config --global user.email "${GIT_USER_EMAIL:-}" 2>/dev/null || true
git config --global pull.rebase true
git config --global init.defaultBranch main

# git SSH key 设置
if [[ ! -f ~/.ssh/id_ed25519.pub ]]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    ssh-keygen -t ed25519 -C "${GIT_USER_EMAIL:-$USER@$(hostname)}" -f ~/.ssh/id_ed25519 -N "" -q
    echo "[OK] SSH key generated: ~/.ssh/id_ed25519"
else
    echo "[SKIP] SSH key already exists"
fi
eval "$(ssh-agent -s)" 2>/dev/null
ssh-add ~/.ssh/id_ed25519 2>/dev/null || true

# 用 gh 把公钥上传到 GitHub
if [[ -n "${GITHUB_TOKEN:-}" ]] && command -v gh &>/dev/null; then
    echo "$GITHUB_TOKEN" | gh auth login --with-token 2>/dev/null
    if ! gh ssh-key list 2>/dev/null | grep -q "$(cat ~/.ssh/id_ed25519.pub | awk '{print $2}')"; then
        gh ssh-key add ~/.ssh/id_ed25519.pub -t "$(hostname)-$(date +%Y%m%d)" 2>/dev/null && \
            echo "[OK] SSH key uploaded to GitHub" || \
            echo "[TODO] SSH key upload failed — 手动: cat ~/.ssh/id_ed25519.pub → https://github.com/settings/keys" >> "$TODO_FILE"
    else
        echo "[SKIP] SSH key already on GitHub"
    fi
    # 让 git 默认走 SSH
    git config --global url."git@github.com:".insteadOf "https://github.com/"
else
    echo "[TODO] GITHUB_TOKEN 未设置 — 需手动上传 SSH key: https://github.com/settings/keys" >> "$TODO_FILE"
fi

echo "[OK] Base CLI tools installed"
```
