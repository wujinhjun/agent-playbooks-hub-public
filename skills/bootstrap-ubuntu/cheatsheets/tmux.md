# Tmux 速查

所有快捷键都是 `Ctrl-b` 之后按下一个键。

## 窗口切换

| 操作 | 快捷键 |
|------|--------|
| 跳到窗口 N (0~9) | `Ctrl-b` `0`~`9` |
| 下一个窗口 | `Ctrl-b` `n` |
| 上一个窗口 | `Ctrl-b` `p` |
| 列出所有窗口 | `Ctrl-b` `w` |
| 新建窗口 | `Ctrl-b` `c` |
| 重命名窗口 | `Ctrl-b` `,` |
| 关掉当前窗口 | `Ctrl-b` `&` 或直接 `exit` |

## 会话管理

| 操作 | 快捷键/命令 |
|------|-----------|
| 断开（后台运行） | `Ctrl-b` `d` |
| 重新连接 | `tmux attach -t agents` |
| 看所有会话 | `tmux ls` |
| 新建会话 | `tmux new -s <name>` |
| 杀会话 | `tmux kill-session -t agents` |
| 一键工作台 | `tmux-bootstrap` |

## 翻屏 / 复制

| 操作 | 快捷键 |
|------|--------|
| 进入翻屏模式 | `Ctrl-b` `[` |
| 翻屏模式中翻页 | `PgUp` / `PgDn` 或 `Ctrl-u` / `Ctrl-d` |
| 退出翻屏 | `q` |
| 搜索 | `Ctrl-b` `[` 然后 `/` 输入关键词 |

## 分屏

| 操作 | 快捷键 |
|------|--------|
| 左右分 | `Ctrl-b` `%` |
| 上下分 | `Ctrl-b` `"` |
| 切换 pane | `Ctrl-b` `o` |
| 关 pane | `Ctrl-b` `x` 或 `exit` |
