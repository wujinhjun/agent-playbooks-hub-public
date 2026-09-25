# Agent Playbooks Hub

Public agent-executable playbooks published from the private source repository.

## Available skills

| Skill | Description |
| --- | --- |
| [`bootstrap-ubuntu`](skills/bootstrap-ubuntu/) | 初始化 Ubuntu 开发环境。当用户说"bootstrap""初始化服务器""配置开发机""装环境""setup server"时触发。交互式模块选择，渐进式安装 Node.js/Go/Python/Docker/mihomo/cc-connect 等，不装不需要的东西。 |

## Install with cc-switch

```bash
cc-switch skills repos add wujinhjun/agent-playbooks-hub-public --app claude
cc-switch skills discover --app claude
cc-switch skills install <skill-name> --app claude
```

> This repository is an automatically generated public mirror. Do not edit it directly.
