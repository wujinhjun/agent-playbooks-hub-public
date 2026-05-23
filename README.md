# Claude Skills — 私有源仓库

我的 Claude Code skills 集中管理仓库。标记 `public: true` 的 skill 自动发布到公开镜像。

## 结构

```
skills/           # 所有 skill（含公开和私密）
scripts/          # 发布脚本
```

## 公开镜像

https://github.com/wujinhjun/claude-skills-public

## 使用

```bash
# 安装后直接用
cc-switch skills repos add wujinhjun/claude-skills-public
cc-switch skills install bootstrap-ubuntu
```

## 开发

新 skill 在 `skills/` 下创建目录，写 `SKILL.md`：

```yaml
---
name: my-skill
public: true   # true=发布到公开镜像, false=仅私有仓库可见
description: 当用户说 xxx 时触发
---
```

推送后 CI 自动同步 `public: true` 的 skill 到公开镜像。
