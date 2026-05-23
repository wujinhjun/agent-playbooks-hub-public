# =============================================================================
# 多 Agent 管理配置 — shell aliases + tmux 工作台 + 目录约定
# 位置: ~/.config/agents/agents.sh
#
# === 通用配置（所有人可用）===
#   cc/ccd/ccm 别名 — 多 provider 快速切换
#   tmux-bootstrap    — 一键建多窗口工作台
#   setup-work-dirs   — 创建工作目录
#   docker-sandbox    — Docker 隔离执行
#   git-worktree-add  — 多分支并发
#   cc-fallback       — provider 自动降级
#
# === 个人定制（需自行修改）===
#   check-sg-ip       — SG IP 守卫，默认禁用。如需启用改 SKIP_IP_CHECK=0
#   TOOL_ALIASES      — 额外的个人别名
# =============================================================================

# ===== IP 守卫（默认禁用，需自行配置）=====
SG_IP="REPLACE_WITH_YOUR_IP"     # 改成你的期望出口 IP
SKIP_IP_CHECK="${SKIP_IP_CHECK:-1}"  # 1=跳过, 0=启用

check-ip() {
    # 通用 IP 守卫 — 检查当前出口 IP 是否匹配 SG_IP
    # 用法: SKIP_IP_CHECK=0 启用守卫
    [[ "${SKIP_IP_CHECK:-1}" == "1" ]] && return 0

    local ip
    for endpoint in "https://httpbin.org/ip" "https://api.ipify.org" "https://ip.sb"; do
        ip=$(curl -s --connect-timeout 5 "$endpoint" 2>/dev/null | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)
        [[ -n "$ip" ]] && break
    done

    if [[ -z "$ip" ]]; then
        echo "?? 无法检测 IP — 代理可能挂了"
        echo "   检查: sudo systemctl status mihomo"
        return 1
    fi

    if [[ "$ip" != "$SG_IP" ]]; then
        echo "?? 当前 IP: $ip，不是期望 IP ($SG_IP)"
        echo "   Anthropic OAuth 可能风控，已拦截"
        echo "   使用 ccd/ccm 走 API，或检查代理"
        return 1
    fi

    echo "?? IP ($SG_IP) — safe"
    return 0
}

# 保留旧名兼容
check-sg-ip() { check-ip "$@"; }

# ===== NOPASSWD sudo =====
setup-sudo() {
    if sudo -n true 2>/dev/null; then
        echo "?? NOPASSWD sudo 已配置"
        return 0
    fi
    echo "?? 配置 NOPASSWD sudo..."
    echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/claude-agent > /dev/null
    sudo chmod 0440 /etc/sudoers.d/claude-agent
    echo "?? NOPASSWD sudo 已启用"
}

# ===== 裸 claude 拦截 =====
claude() {
    echo "?? 禁止裸 claude！要用:"
    echo "   cc  [-s] [-y]  = official (OAuth)"
    echo "   ccd [-s] [-y]  = deepseek (API)"
    echo "   ccm [-s] [-y]  = minimax (API)"
    echo ""
    echo "   -s: 先配置 NOPASSWD sudo 再启动"
    echo "   -y: bypass 权限确认"
    return 1
}

# ===== Claude Code 别名 =====
# 每个 provider 独立，不互相干扰

cc() {
    local sudo="" bypass="" args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s) sudo=1; shift ;;
            -y) bypass="--dangerously-skip-permissions"; shift ;;
            -sy|-ys) sudo=1; bypass="--dangerously-skip-permissions"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done
    [[ "$sudo" == 1 ]] && setup-sudo
    check-ip || return 1
    cc-switch start claude claude-official -- $bypass "${args[@]}"
}

ccd() {
    local sudo="" bypass="" args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s) sudo=1; shift ;;
            -y) bypass="--dangerously-skip-permissions"; shift ;;
            -sy|-ys) sudo=1; bypass="--dangerously-skip-permissions"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done
    [[ "$sudo" == 1 ]] && setup-sudo
    cc-switch start claude deepseek -- $bypass "${args[@]}"
}

ccm() {
    local sudo="" bypass="" args=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s) sudo=1; shift ;;
            -y) bypass="--dangerously-skip-permissions"; shift ;;
            -sy|-ys) sudo=1; bypass="--dangerously-skip-permissions"; shift ;;
            *) args+=("$1"); shift ;;
        esac
    done
    [[ "$sudo" == 1 ]] && setup-sudo
    cc-switch start claude minimax -- $bypass "${args[@]}"
}

# 全局 fallback
cc-fallback() {
    local providers=(deepseek minimax)
    for p in "${providers[@]}"; do
        cc-switch provider switch "$p" && command claude -p "$1" && break
    done
}

# ===== 其他 Agent 别名 =====
alias cx='codex'
alias gm='gemini'
alias ad='aider --model deepseek/deepseek-chat'
alias oc='opencode'

# ===== 个人工具别名（可自行增删）=====
# alias my-task='...'

# ===== 工作目录约定 =====
setup-work-dirs() {
    local user_home="${1:-$HOME}"
    mkdir -p "$user_home/workspace"/{agents,sandbox,_logs}
    echo "[OK] Work directories created under $user_home/workspace/"
}

# ===== tmux 多 Agent 工作台 =====
tmux-bootstrap() {
    local session="agents"
    tmux has-session -t "$session" 2>/dev/null && {
        echo "[INFO] tmux session '$session' already exists. Attach: tmux attach -t $session"
        return 0
    }

    tmux new-session  -d -s "$session" -n cc-official
    tmux new-window   -t "$session:"  -n cc-deepseek
    tmux new-window   -t "$session:"  -n cc-minimax
    tmux new-window   -t "$session:"  -n codex
    tmux new-window   -t "$session:"  -n shell

    tmux send-keys -t "$session:cc-official" 'cd ~/workspace && cc'  C-m
    tmux send-keys -t "$session:cc-deepseek"  'cd ~/workspace && ccd' C-m
    tmux send-keys -t "$session:cc-minimax"   'cd ~/workspace && ccm' C-m
    tmux send-keys -t "$session:codex"        'cd ~/workspace && codex'     C-m
    tmux send-keys -t "$session:shell"        'cd ~/workspace'              C-m

    echo "[OK] tmux session '$session' created. Attach: tmux attach -t $session"
}

# ===== Docker 沙箱 =====
docker-sandbox() {
    local dir="${1:-$PWD}"
    docker run --rm -it \
        -v "$dir":/workspace -w /workspace \
        --network=none \
        ghcr.io/anthropics/claude-code:latest claude --dangerously-skip-permissions
}

# ===== git worktree 多分支并发 =====
git-worktree-add() {
    local branch_a="${1:-feature/a}"
    local branch_b="${2:-feature/b}"
    git worktree add ~/workspace/agents/myrepo-"$branch_a" "$branch_a" 2>/dev/null || true
    git worktree add ~/workspace/agents/myrepo-"$branch_b" "$branch_b" 2>/dev/null || true
    echo "[OK] worktrees: ~/workspace/agents/myrepo-$branch_a + ~/workspace/agents/myrepo-$branch_b"
}

# ===== CLI 入口 =====
if [[ "$1" == "--tmux-bootstrap" ]]; then
    setup-work-dirs
    tmux-bootstrap
elif [[ "$1" == "--setup-dirs" ]]; then
    setup-work-dirs
fi
