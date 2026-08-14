# Claude Skills — 私有源仓库

我的 Claude Code skills 集中管理仓库。

## Skills 一览

| Skill | 用途 | 平台 |
| ------- | ------ | ------ |
| `cc-setup` | 交互式配置 cc-switch 多 provider 和 shell 别名 | macOS / Linux |
| `dev-env` | CLI 开发运行时环境（Node/Go/Python/Java/Rust 等） | macOS / Linux |
| `mac-apps` | macOS GUI 工作应用（效率/AI/编辑器/终端） | macOS only |
| `bootstrap-ubuntu` | Ubuntu 开发环境一键初始化（20+ 模块） | Ubuntu |

## 安装方式

### 方式一：install.sh 逐 skill 注册（无需 cc-switch）

```bash
git clone git@github.com:wujinhjun/claude-skills.git ~/claude-skills
cd ~/claude-skills

./scripts/install.sh            # 安装全部（已装过的自动跳过，冲突会询问）
./scripts/install.sh mac-apps   # 或只装指定的
./scripts/install.sh --list     # 查看安装状态
./scripts/install.sh --remove mac-apps   # 卸载某个 skill
```

symlink 方式，`git pull` 即可更新；仓库新增 skill 后再跑一次 `install.sh` 即可（幂等）。

### 方式二：cc-switch 管理（支持版本切换、启停）

```bash
brew tap farion1231/ccswitch && brew install cc-switch-cli   # 如未装
git clone git@github.com:wujinhjun/claude-skills.git ~/claude-skills

cc-switch skills repos add ~/claude-skills --app claude
cc-switch skills sync-method symlink --app claude

# 发现并安装
cc-switch skills discover --app claude
cc-switch skills install <skill-name> --app claude
```

## 开发

在 `skills/` 下创建目录，写 `SKILL.md`：

```yaml
---
name: my-skill
public: true   # true = 自动发布到公开镜像, false = 仅私有仓库可见
description: 当用户说 xxx 时触发
---
```

推送到 `main` 后 CI 自动同步 `public: true` 的 skill 到公开镜像。
