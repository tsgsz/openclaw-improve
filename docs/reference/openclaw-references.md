# 参考文档

## OpenClaw 官方文档

- [Hooks 文档](https://www.openclaw.ai/automation/hooks)
- [Agent 系统](https://www.openclaw.ai/concepts/agents)
- [Session 管理](https://www.openclaw.ai/concepts/sessions)
- [配置指南](https://www.openclaw.ai/gateway/configuration)

## 相关源码

### Hooks
- `~/workspace/openclaw/src/hooks/` - Hooks 核心实现
- `~/workspace/openclaw/src/hooks/bundled/` - 内置 hooks
- `~/workspace/openclaw/docs/automation/hooks.md` - Hooks 文档

### Agent Tools
- `~/workspace/openclaw/src/agents/tools/sessions-spawn-tool.ts` - Spawn 工具
- `~/workspace/openclaw/src/agents/tools/sessions-send-tool.a2a.ts` - Session 通信
- `~/workspace/openclaw/src/agents/tools/sessions-history-tool.ts` - Session 历史

### Skills
- `~/.openclaw/skills/using-superpowers/` - 超能力技能
- `~/.openclaw/skills/planning-with-files/` - 文件规划技能

## 配置文件

- `~/.openclaw/openclaw.json` - 主配置文件
- `~/.openclaw/agents/*/agent.json` - Agent 配置
- `~/.openclaw/hooks/*/HOOK.md` - Hook 元数据

## 数据文件

- `~/.openclaw/runtime.json` - 任务运行时状态 (新增)
- `~/.openclaw/workspace/projects/project.json` - 项目注册表 (新增)
- `~/.openclaw/subagents/run.json` - 当前运行任务 (原生)
