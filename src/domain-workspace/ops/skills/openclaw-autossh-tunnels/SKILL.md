---
name: openclaw-autossh-tunnels
description: 管理 macOS 上的 OpenClaw 反向 SSH 隧道 (autossh + launchctl)。当用户要求启动/停止/重启/检查 autossh 隧道状态，查看日志，或更改 Mac↔VPS 隧道的转发端口（com.openclaw.autossh-tunnels LaunchAgent，端口 2222 和 18789）时使用。
---

> 运行说明：本技能为执行型技能，按当前 Runner 架构使用。

# OpenClaw autossh 隧道（macOS）

本机使用 LaunchAgent 来保持反向 SSH 隧道存活：
- 标签: `com.openclaw.autossh-tunnels`
- 脚本: `scripts/openclaw-tunnels.sh`
- Plist: `~/Library/LaunchAgents/com.openclaw.autossh-tunnels.plist`
- 日志:
  - `~/.openclaw/logs/autossh-tunnels.out.log`
  - `~/.openclaw/logs/autossh-tunnels.err.log`

首选下面的捆绑控制脚本（它使用绝对路径且可重复执行）。

## 控制脚本

使用方法：

```bash
zsh ~/.openclaw/workspace/skill-catalog/project/openclaw-autossh-tunnels/scripts/tunnelsctl.zsh <cmd>
```

命令：
- `status` – 显示 launchctl 状态 + VPS 监听端口 (2222 + 18789)
- `restart` – 重启 LaunchAgent
- `stop` – 卸载 (bootout/unload) LaunchAgent
- `start` – 引导启动 (bootstrap) + 启用 + 启动 LaunchAgent
- `logs` – 追踪隧道日志
- `where` – 打印关键路径 (script/plist/logs)

## 更改隧道参数 (端口 / VPS 主机)

1) 编辑 `scripts/openclaw-tunnels.sh` (这是 autossh 运行的脚本)。
2) 然后运行 `tunnelsctl.zsh restart`。

重要不变量 (安全)：
- 仪表板转发应在 VPS 上保持仅回环：`-R 127.0.0.1:18789:127.0.0.1:18789`
- SSH 访问转发可以在 VPS 上公开：`-R 0.0.0.0:2222:127.0.0.1:22`

如果用户要求公开发布仪表板，请在更改前明确确认。


## 参考资料
- references/litellm-sssaicode-setup.md
