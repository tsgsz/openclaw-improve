# OpenClaw Task Dispatch Plugin - 最终方案

## 一、问题与目标

### 当前问题
1. Subagent 失联（announce 队列丢失）
2. sessions_spawn 异步不可靠
3. 派发决策不稳定

### 解决目标
- 统一的 task_sync/task_async 接口
- 保证回执，不丢失
- 支持动态 project 和 model
- 零侵入 OpenClaw

## 二、核心方案

### 统一接口

```typescript
// 串行：阻塞等待
task_sync({ agent: "researcher", task: "分析代码" })

// 并发：异步跟踪
task_async({ 
  agent: "coder", 
  task: "实现认证",
  project_root: "/path/to/project",
  model: "openai/gpt-4"
})

// 检查状态
task_check()
```

### 架构层次

```
Main (用户层)
  - 工具: task_async
  - 禁用: task_sync, sessions_spawn
  - Skills: 通过 skill 触发 domain agents
  - 可调用: orchestrator
  ↓
Orchestrator (协调层)
  - 工具: task_sync, task_async, task_check
  - 可调用: functional agents
  ↓
Domain Agents (领域专家层)
  - 通过 Main 的 skill 触发
  - domain-finance, domain-creative, domain-ops
  - 工具: task_sync, task_async
  - 可调用: functional agents
  ↓
Functional Agents (功能执行层)
  - professor: web research + citations
  - sculpture: local read-only exploration
  - writter: long-form doc writing
  - geek: scripts/tooling packages
  - coder: 工程化代码修改（ACP runtime）
  - reviewer: 质量审查、挑刺（使用不同模型如 Gemini）
  - 专注具体任务执行
```

**调用方式**：
- Main → Orchestrator：直接 task_async
- Main → Domain Agent：通过 skill 触发（skill 内部调用 task_async）
- Orchestrator → Functional Agent：task_sync/task_async
- Domain Agent → Functional Agent：task_sync/task_async

## 三、Agent 配置

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "workspace": "~/.openclaw/workspace/main",
        "tools": {
          "allow": ["task_async"],
          "deny": ["task_sync", "sessions_spawn"]
        },
        "subagents": { "allowAgents": ["orchestrator"] }
      },
      {
        "id": "orchestrator",
        "tools": { "allow": ["task_sync", "task_async", "task_check"] },
        "subagents": { "allowAgents": ["professor", "sculpture", "writter", "geek", "coder", "reviewer"] }
      },
      {
        "id": "domain-finance",
        "workspace": "~/.openclaw/workspace/domains/finance",
        "tools": { "allow": ["task_sync", "task_async"] },
        "subagents": { "allowAgents": ["professor", "sculpture", "writter", "geek", "coder", "reviewer"] }
      },
      {
        "id": "domain-creative",
        "workspace": "~/.openclaw/workspace/domains/creative",
        "tools": { "allow": ["task_sync", "task_async"] },
        "subagents": { "allowAgents": ["professor", "sculpture", "writter", "geek", "coder", "reviewer"] }
      },
      {
        "id": "professor",
        "tools": { "allow": ["web_search", "read", "grep"] }
      },
      {
        "id": "sculpture",
        "tools": { "allow": ["read", "grep", "glob"] }
      },
      {
        "id": "writter",
        "tools": { "allow": ["read", "write", "edit"] }
      },
      {
        "id": "geek",
        "tools": { "allow": ["bash", "read", "write"] }
      },
      {
        "id": "coder",
        "runtime": "acp",
        "command": "opencode",
        "workspace": "~/.openclaw/workspace/functional/coder"
      },
      {
        "id": "reviewer",
        "model": "google/gemini-2.0-flash-exp:free",
        "tools": { "allow": ["read", "grep", "glob"] }
      }
    ]
  }
}
```

## 四、Plugin 实现

### task_sync（串行）

```typescript
async function task_sync(params: { agent: string, task: string, timeout_ms?: number }) {
  const { runId } = await api.runtime.subagent.run({
    sessionKey: `sync-${Date.now()}`,
    message: params.task,
    deliver: false
  });
  
  const result = await api.runtime.subagent.waitForRun({
    runId,
    timeoutMs: params.timeout_ms || 300000
  });
  
  const { messages } = await api.runtime.subagent.getSessionMessages({
    sessionKey,
    limit: 100
  });
  
  return { content: [{ type: "text", text: extractResult(messages) }] };
}
```

### task_async（并发）

```typescript
const taskRegistry = new Map();

async function task_async(params: { 
  agent: string, 
  task: string,
  project_root?: string,
  model?: string,
  timeout_ms?: number
}) {
  const taskId = `task-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  const sessionKey = `async-${taskId}`;
  
  if (params.agent === "coder") {
    const result = await sessions_spawn({
      runtime: "acp",
      agentId: "opencode",
      task: params.task,
      cwd: params.project_root,
      model: params.model,
      runTimeoutSeconds: params.timeout_ms ? params.timeout_ms / 1000 : undefined
    });
    taskRegistry.set(taskId, { sessionKey, status: "running", agent: params.agent });
  } else {
    const { runId } = await api.runtime.subagent.run({
      sessionKey,
      message: params.task,
      deliver: true
    });
    taskRegistry.set(taskId, { sessionKey, runId, status: "running", agent: params.agent });
  }
  
  return { content: [{ type: "text", text: `Task started: ${taskId}` }] };
}
```

### task_check（状态查询）

```typescript
async function task_check(params?: { task_id?: string }) {
  if (params?.task_id) {
    const task = taskRegistry.get(params.task_id);
    if (!task) return { content: [{ type: "text", text: "Task not found" }] };
    return { content: [{ type: "text", text: JSON.stringify(task, null, 2) }] };
  }
  
  const allTasks = Array.from(taskRegistry.entries()).map(([id, task]) => ({
    task_id: id,
    ...task
  }));
  return { content: [{ type: "text", text: JSON.stringify(allTasks, null, 2) }] };
}
```

### Hook 实现（subagent_ended）

```typescript
api.hooks.on("subagent_ended", async (event: PluginHookSubagentEndedEvent) => {
  for (const [taskId, task] of taskRegistry.entries()) {
    if (task.sessionKey === event.targetSessionKey) {
      if (event.outcome === "success") {
        const { messages } = await api.runtime.subagent.getSessionMessages({
          sessionKey: event.targetSessionKey,
          limit: 100
        });
        task.status = "completed";
        task.result = extractResult(messages);
      } else {
        task.status = "failed";
        task.error = event.error;
      }
      break;
    }
  }
});

function extractResult(messages: any[]) {
  const lastAssistant = messages.reverse().find(m => m.role === "assistant");
  return lastAssistant?.content || "No result";
}
```

## 五、完整执行流程

### 场景 1：Main → Orchestrator → Coder（串行）

```
用户: "实现用户认证功能"
  ↓
Main: task_async({ agent: "orchestrator", task: "实现用户认证" })
  ↓
Orchestrator: task_sync({ agent: "coder", task: "实现 JWT 认证", project_root: "/path/to/project" })
  ↓ (阻塞等待)
Coder (ACP): 执行代码修改
  ↓
Orchestrator: 收到结果，继续工作
  ↓
Main: 收到 subagent_ended 通知，task_check 查看结果
```

### 场景 2：Orchestrator 并发派发

```
Orchestrator 收到任务: "分析并重构支付模块"
  ↓
task_async({ agent: "researcher", task: "分析支付流程" })  // 并发 1
task_async({ agent: "architect", task: "设计重构方案" })   // 并发 2
  ↓
task_check()  // 查询状态
  ↓
等待 subagent_ended hook 通知
  ↓
收集结果，继续工作
```

### 场景 3：Domain Agent 调用 Functional Agents

```
用户: "分析金融数据并生成报告"
  ↓
Main: task_async({ agent: "domain-finance", task: "分析 Q4 财报" })
  ↓
Domain-Finance: 
  - task_sync({ agent: "researcher", task: "收集财报数据" })
  - task_sync({ agent: "coder", task: "生成图表", project_root: "/reports" })
  ↓
Domain-Finance: 整合结果，生成专业报告
  ↓
Main: 收到完整报告
```

## 六、安装与配置

### 1. 安装 Plugin

```bash
cd ~/.openclaw/plugins
git clone <plugin-repo> task-dispatch
cd task-dispatch
npm install
npm run build
```

### 2. 配置 openclaw.json

```json
{
  "plugins": {
    "task-dispatch": {
      "enabled": true,
      "config": {
        "taskTimeout": 300000,
        "maxConcurrentTasks": 10
      }
    }
  },
  "agents": {
    "list": [
      {
        "id": "main",
        "default": true,
        "tools": {
          "allow": ["task_async"],
          "deny": ["task_sync", "sessions_spawn"]
        },
        "subagents": { "allowAgents": ["orchestrator"] }
      },
      {
        "id": "orchestrator",
        "tools": { "allow": ["task_sync", "task_async", "task_check"] },
        "subagents": { "allowAgents": ["researcher", "architect", "coder"] }
      },
      {
        "id": "coder",
        "runtime": "acp",
        "command": "opencode",
        "workspace": "~/.openclaw/workspace/coder"
      }
    ]
  }
}
```

### 3. 配置 Workspace（可选）

为 coder agent 配置 skills：

```bash
mkdir -p ~/.openclaw/workspace/functional/coder/skills
# 复制需要的 skills 到该目录
```

### 4. 配置 Domain Agent Skills

每个 Domain Agent 需要配套的 skill 来定义调用方式。

**示例：~/.openclaw/workspace/main/skills/domain-finance.md**

```markdown
# Domain Finance Agent

金融领域专家，负责财务分析、报表生成、数据处理等任务。

## 何时使用

- 财务数据分析
- 财报生成
- 金融指标计算
- 投资组合分析

## 调用方式

使用 task_async 调用 domain-finance agent：

\`\`\`typescript
task_async({
  agent: "domain-finance",
  task: "分析 Q4 财报并生成可视化报告"
})
\`\`\`

## 能力

- 可以调用 researcher 收集数据
- 可以调用 coder 生成图表和报告
- 可以调用 architect 设计数据模型
```

**示例：~/.openclaw/workspace/main/skills/domain-creative.md**

```markdown
# Domain Creative Agent

创意设计专家，负责 UI/UX 设计、视觉创意、内容创作等任务。

## 何时使用

- UI/UX 设计
- 品牌视觉设计
- 创意文案
- 多媒体内容创作

## 调用方式

\`\`\`typescript
task_async({
  agent: "domain-creative",
  task: "设计产品落地页，包含响应式布局和动画效果"
})
\`\`\`

## 能力

- 可以调用 researcher 进行设计调研
- 可以调用 coder 实现前端代码
- 可以调用 architect 设计组件架构
```

## 七、关键设计决策

### 为什么用 Hook 而不是轮询？

- Hook 是事件驱动，零延迟
- 轮询浪费资源，有延迟
- OpenClaw 原生支持 subagent_ended hook

### 为什么 Coder 用 ACP？

- ACP 支持动态 cwd（project_root）
- ACP 支持动态 model
- 一个 session = 一个独立进程，隔离性好
- OpenCode 推荐使用 ACP runtime

### 为什么不传递 Skills？

- Skills 绑定到 workspace，不能作为参数
- 通过预配置 agent workspace 解决
- 保持 OpenClaw 原生机制

### 为什么分三层？

- Main：用户交互层，禁止直接操作代码
- Orchestrator：决策层，负责任务分解和派发
- Workers：执行层，专注具体任务
- 符合 AGENTS.md 的约束

## 八、迁移指南

### 从当前配置迁移

当前 AGENTS.md 配置过于复杂，建议简化：

**保留**：
- main（用户层）
- orchestrator（协调层）
- researcher, architect, coder（执行层）

**删除**：
- 重复的 domain-* agents（通过 workspace 配置实现）
- 冗余的 launchd 配置（ACP 自动管理进程）

**Skills 迁移**：
- 将 skills 移动到对应 agent 的 workspace
- 不需要在 agent 配置中声明 skills

## 九、参考文档

- `opencode-subagent-analysis.md` - OpenCode 机制分析
- `README.md` - 项目背景和问题描述
- `~/.openclaw/workspace/AGENTS.md` - 当前配置参考

