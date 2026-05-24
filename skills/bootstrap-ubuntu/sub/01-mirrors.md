# 01 — Mirror Sources

```bash
#!/bin/bash
set -e
PRIV_DIR="$HOME/.config/bootstrap-ubuntu"
source "$PRIV_DIR/bootstrap.env" 2>/dev/null || true

[[ "${INSTALL_MIRRORS:-N}" != "Y" ]] && { echo "[SKIP] mirrors"; exit 0; }

# 1.1 APT → 清华源
[[ ! -f /etc/apt/sources.list.bak ]] && sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true
sudo sed -i "s|http://.*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g" /etc/apt/sources.list.d/*.sources 2>/dev/null || true
sudo sed -i "s|http://.*archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g" /etc/apt/sources.list 2>/dev/null || true
sudo sed -i "s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g" /etc/apt/sources.list.d/*.sources 2>/dev/null || true
sudo sed -i "s|http://security.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|g" /etc/apt/sources.list 2>/dev/null || true
sudo apt update -qq
echo "[OK] APT → tuna.tsinghua"

# 1.2 pip
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<'PIPEOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
PIPEOF
echo "[OK] pip → tuna.tsinghua"

# 1.3 cargo
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml <<'CARGOEOF'
[source.crates-io]
replace-with = "tuna"

[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"
CARGOEOF
echo "[OK] cargo → tuna.tsinghua"

# 1.4 conda
mkdir -p ~/.conda
cat > ~/.condarc <<'CONDAEOF'
channels: [defaults]
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
CONDAEOF
echo "[OK] conda → tuna.tsinghua"

# 1.5 Docker registry mirror (preset)
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'DOCKEREOF'
{"registry-mirrors":["https://docker.1ms.run"]}
DOCKEREOF
echo "[OK] Docker mirror preset"

# 1.6 Go proxy (preset — go may not be installed yet)
command -v go >/dev/null 2>&1 && go env -w GOPROXY=https://goproxy.cn,direct || true
echo "[OK] Go proxy preset"
```
