# Openclaw 增强形态 - 设计总览

## 核心增强

基于 README.md 的需求，在现有 openclaw 架构上增强：

1. **Spawn 监控** - 强制项目选择、ETA 预估、运行时监控
2. **项目管理** - 永久/临时项目、自动 git 管理
3. **Agent 分层** - Functional/Domain agents 明确职责

## 文档索引

- [01-spawn-monitoring.md](./01-spawn-monitoring.md) - Spawn 监控系统
- [02-project-management.md](./02-project-management.md) - 项目管理
- [03-agent-design.md](./03-agent-design.md) - Agent 设计
- [04-implementation.md](./04-implementation.md) - 实现细节

## 关键发现（基于源码调研）

### Hook 系统架构

OpenClaw 有**两套独立的 Hook 系统**：

#### 1. Internal Hooks（内部钩子）
**源码**: `src/hooks/internal-hooks.ts`  
**格式**: `type:action`  
**用途**: 核心功能的内置事件

- `command:new`, `command:reset`, `command:stop`
- `message:received`, `message:preprocessed`, `message:transcribed`, `message:sent`
- `agent:bootstrap`
- `gateway:startup`
- `session:compact:before`, `session:compact:after`

#### 2. Plugin Hooks（插件钩子）
**源码**: `src/plugins/types.ts` (lines 321-372)  
**格式**: 下划线分隔  
**用途**: 插件扩展系统（现代化方案）

**Subagent 相关** (4个):
- `subagent_spawning`, `subagent_spawned`
- `subagent_delivery_target`, `subagent_ended`

**其他** (20个):
- Agent: `before_model_resolve`, `before_prompt_build`, `before_agent_start`, `llm_input`, `llm_output`, `agent_end`, `before_compaction`, `after_compaction`, `before_reset`
- Message: `message_received`, `message_sending`, `message_sent`
- Tool: `before_tool_call`, `after_tool_call`, `tool_result_persist`, `before_message_write`
- Session: `session_start`, `session_end`
- Gateway: `gateway_start`, `gateway_stop`

### 实际的数据结构
- `~/.openclaw/subagents/runs.json` - 当前运行的 subagent
- `~/.openclaw/agents/<agent-name>/agent/models.json` - Agent 模型配置
- `~/.openclaw/agents/<agent-name>/sessions/` - Session 数据

### Hook 结构
```
~/.openclaw/hooks/<hook-name>/
├── HOOK.md          # 元数据 + 文档
└── handler.ts       # 实现
```

## 设计原则

1. **最小改动** - 基于现有结构扩展，不破坏原有习惯
2. **实际可行** - 使用真实存在的事件和API
3. **渐进实施** - 可以分阶段实现和测试
