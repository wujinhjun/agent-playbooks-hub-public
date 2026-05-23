# Claude Skills — 私有源仓库

我的 Claude Code skills 集中管理仓库。标记 `public: true` 的 skill 通过 CI 自动发布到公开镜像。

## Skills 一览

### bootstrap-ubuntu

Ubuntu 开发环境一键初始化。AI 交互式引导，用户勾选需要的模块（Node.js / Go / Python / Docker / mihomo / cc-connect / tmux 工作台等 20+ 模块），渐进式安装，不装不需要的东西。

```
cc-switch skills repos add wujinhjun/claude-skills-public
cc-switch skills install bootstrap-ubuntu
```

## 公开镜像

https://github.com/wujinhjun/claude-skills-public

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
