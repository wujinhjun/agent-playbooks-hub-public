# 04 — Language Runtimes

每个运行时独立，只有用户在 Step 1 中勾选的才安装。变量 `INSTALL_NODE/GO/PYTHON/JAVA/RUST/FLUTTER` 控制。

```bash
#!/bin/bash
set -e

# ---- nvm + Node + pnpm ----
if [[ "${INSTALL_NODE:-N}" == "Y" ]]; then
    if [[ ! -d ~/.nvm ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
        npm install -g pnpm
        echo "[OK] nvm + Node LTS + pnpm"
    else
        echo "[SKIP] nvm already installed"
    fi
fi

# ---- gvm + Go (with direct install fallback) ----
if [[ "${INSTALL_GO:-N}" == "Y" ]]; then
    if [[ ! -d ~/.gvm ]]; then
        bash < <(curl -sSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
        source ~/.gvm/scripts/gvm
        gvm install go1.23 -B 2>&1 || true
        if ! gvm use go1.23 --default 2>/dev/null; then
            GO_VER="1.23.4"
            wget -q "https://go.dev/dl/go${GO_VER}.linux-amd64.tar.gz" -O /tmp/go.tar.gz
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            echo 'export PATH=/usr/local/go/bin:$PATH' >> ~/.bashrc
            export PATH=/usr/local/go/bin:$PATH
            echo "[OK] Go $GO_VER (direct install fallback)"
        else
            echo "[OK] gvm + Go 1.23"
        fi
        go env -w GOPROXY=https://goproxy.cn,direct 2>/dev/null || true
    else
        echo "[SKIP] gvm already installed"
    fi
fi

# ---- Python: uv + miniconda ----
if [[ "${INSTALL_PYTHON:-N}" == "Y" ]]; then
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        echo "[OK] uv"
    else
        echo "[SKIP] uv already installed"
    fi
    if [[ ! -d ~/miniconda3 ]]; then
        mkdir -p ~/miniconda3
        wget -q https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
        bash /tmp/miniconda.sh -b -u -p ~/miniconda3
        ~/miniconda3/bin/conda init bash
        echo "[OK] Miniconda"
    else
        echo "[SKIP] Miniconda already installed"
    fi
fi

# ---- sdkman + Java (with manual extraction fallback) ----
if [[ "${INSTALL_JAVA:-N}" == "Y" ]]; then
    if [[ ! -d ~/.sdkman ]]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        if sdk install java 2>&1; then
            echo "[OK] sdkman + Java"
        else
            JDK_TMP=$(ls ~/.sdkman/tmp/java-*.bin 2>/dev/null | head -1)
            JDK_VER=$(ls ~/.sdkman/var/metadata/ 2>/dev/null | grep java | head -1 | sed 's/\.headers//')
            if [[ -n "$JDK_TMP" && -n "$JDK_VER" ]]; then
                mkdir -p ~/.sdkman/candidates/java/"$JDK_VER"
                cd ~/.sdkman/candidates/java/"$JDK_VER"
                gunzip -c "$JDK_TMP" | tar xf -
                ln -sfn jdk-* current 2>/dev/null || true
                echo "[OK] sdkman + Java (manual extraction)"
            fi
        fi
    else
        echo "[SKIP] sdkman already installed"
    fi
fi

# ---- rustup + cargo ----
if [[ "${INSTALL_RUST:-N}" == "Y" ]]; then
    if ! command -v rustup &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        echo "[OK] rustup + cargo"
    else
        echo "[SKIP] rustup already installed"
    fi
fi

# ---- Flutter + FVM ----
if [[ "${INSTALL_FLUTTER:-N}" == "Y" ]]; then
    if ! command -v fvm &>/dev/null; then
        # fvm 需要 Dart — 先装 Dart SDK
        if ! command -v dart &>/dev/null; then
            sudo apt install -y dart 2>/dev/null || {
                DART_VER="3.8.5"
                wget -q "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VER}/sdk/dartsdk-linux-x64-release.zip" -O /tmp/dart.zip
                sudo unzip -q /tmp/dart.zip -d /usr/local/dart
                sudo ln -sf /usr/local/dart/dart-sdk/bin/dart /usr/local/bin/dart
            }
        fi
        dart pub global activate fvm
        export PATH="$HOME/.pub-cache/bin:$PATH"
        echo 'export PATH="$HOME/.pub-cache/bin:$PATH"' >> ~/.bashrc
        fvm install stable
        fvm global stable
        echo "[OK] fvm + Flutter stable"
    else
        echo "[SKIP] fvm already installed"
    fi
fi

# Source selected frameworks for immediate use
[[ "${INSTALL_NODE:-N}" == "Y" ]] && { source ~/.nvm/nvm.sh 2>/dev/null || true; }
[[ "${INSTALL_GO:-N}" == "Y" ]] && { source ~/.gvm/scripts/gvm 2>/dev/null || true; }
[[ "${INSTALL_RUST:-N}" == "Y" ]] && { source "$HOME/.cargo/env" 2>/dev/null || true; }
[[ "${INSTALL_JAVA:-N}" == "Y" ]] && { source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true; }
echo "[OK] Selected runtimes sourced"
```
