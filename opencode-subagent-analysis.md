# OpenCode Subagent 分发机制深度分析

## 核心问题

1. **Loop 机制**：什么阶段拆解 subagent，通过什么机制
2. **同步/异步**：如何保证 subagent 完成后 main 继续工作
3. **决策机制**：谁决定由哪个 subagent 接管，在哪里决定，如何保证稳定性

---

## 一、Loop 机制：什么阶段拆解 subagent

### 核心 Loop 位置

**文件：** `packages/opencode/src/session/prompt.ts`

**函数：** `SessionPrompt.loop()`

### Loop 流程图

```
用户发送消息
  ↓
SessionPrompt.prompt()
  ├─ createUserMessage() - 创建用户消息
  └─ loop() - 进入主循环
      ↓
while (true) {
  ├─ 1. 读取消息历史
  │   └─ MessageV2.filterCompacted(MessageV2.stream(sessionID))
  │
  ├─ 2. 分析最后的消息状态
  │   ├─ lastUser: 最后一条用户消息
  │   ├─ lastAssistant: 最后一条助手消息
  │   ├─ lastFinished: 最后一条完成的助手消息
  │   └─ tasks: 待处理的 subtask/compaction
  │
  ├─ 3. 判断是否退出循环
  │   └─ if (lastAssistant.finish && finish !== "tool-calls")
  │       break - 退出循环
  │
  ├─ 4. 处理 pending subtask (关键！)
  │   └─ if (task?.type === "subtask") {
  │       ├─ 调用 TaskTool.execute()
  │       ├─ 创建子会话 (Session.create)
  │       ├─ 在子会话中执行 SessionPrompt.prompt()
  │       └─ 等待子会话完成，返回结果
  │       └─ continue - 回到循环开始
  │     }
  │
  ├─ 5. 处理 compaction
  │   └─ if (task?.type === "compaction") { ... }
  │
  ├─ 6. 正常 LLM 调用
  │   ├─ resolveTools() - 解析可用工具
  │   ├─ SessionProcessor.process() - 调用 LLM
  │   └─ 处理 tool calls
  │       └─ 如果 LLM 调用了 task 工具
  │           └─ 创建 subtask part
  │               └─ 下一轮循环会在步骤 4 处理
  │
  └─ 7. 检查是否需要继续
      └─ if (result === "stop") break
}
```

### 关键发现：两阶段拆解

**阶段 1：LLM 决策阶段（步骤 6）**

```typescript
// 文件：packages/opencode/src/session/prompt.ts (line ~600)

// LLM 调用，可以使用 task 工具
const result = await processor.process({
  user: lastUser,
  agent,
  messages: MessageV2.toModelMessages(msgs, model),
  tools,  // 包含 task 工具
  model,
})
```

- LLM 在这个阶段可以调用 `task` 工具
- 调用 `task` 工具会创建一个 `subtask` part
- **但不会立即执行**，只是记录到消息历史中

**阶段 2：Subtask 执行阶段（步骤 4）**

```typescript
// 文件：packages/opencode/src/session/prompt.ts (line ~351)

// 下一轮循环开始时，检查是否有 pending subtask
if (task?.type === "subtask") {
  const taskTool = await TaskTool.init()
  
  // 创建子会话
  const result = await taskTool.execute(taskArgs, taskCtx)
  
  // 等待子会话完成
  // ...
  
  continue  // 回到循环开始
}
```

- 循环开始时，先检查是否有 pending subtask
- 如果有，**优先执行 subtask**，而不是调用 LLM
- Subtask 执行完成后，`continue` 回到循环开始
- 下一轮循环会读取包含 subtask 结果的消息历史，再调用 LLM

### 为什么要两阶段？

**优势：**

1. **解耦决策和执行**：LLM 只负责决定"要不要派发 subagent"，不负责执行
2. **可中断**：在 subtask 执行前，可以检查权限、取消等
3. **可恢复**：如果 subtask 执行失败，可以重试或跳过
4. **消息历史完整**：subtask 的输入和输出都记录在消息历史中

---

## 二、同步/异步：如何保证 subagent 完成后 main 继续工作

### 核心机制：**同步等待 + 递归 loop**

**关键代码：**

```typescript
// 文件：packages/opencode/src/tool/task.ts (line ~100)

export const TaskTool = Tool.define("task", async (ctx) => {
  // ...
  
  async execute(params, ctx) {
    // 1. 创建子会话
    const session = await Session.create({
      parentID: ctx.sessionID,  // 记录父会话 ID
      title: params.description + ` (@${agent.name} subagent)`,
      // ...
    })
    
    // 2. 在子会话中调用 SessionPrompt.prompt()
    const result = await SessionPrompt.prompt({
      messageID,
      sessionID: session.id,  // 子会话 ID
      model: { ... },
      agent: agent.name,
      parts: promptParts,
    })
    
    // 3. 等待子会话完成（同步等待）
    const text = result.parts.findLast((x) => x.type === "text")?.text ?? ""
    
    // 4. 返回结果给父会话
    return {
      title: params.description,
      metadata: { sessionId: session.id },
      output: [
        `task_id: ${session.id}`,
        "<task_result>",
        text,
        "</task_result>",
      ].join("\n")
    }
  }
})
```

### 执行流程

```
Main Session Loop (step N)
  ↓
LLM 调用 task 工具
  ├─ 创建 subtask part（记录到消息历史）
  └─ finish = "tool-calls"
  ↓
Main Session Loop (step N+1)
  ├─ 检测到 pending subtask
  ├─ 调用 TaskTool.execute()
  │   ↓
  │   创建 Sub Session
  │   ↓
  │   Sub Session Loop (递归调用 SessionPrompt.loop)
  │   ├─ step 1: LLM 调用
  │   ├─ step 2: 执行工具
  │   ├─ step 3: LLM 调用
  │   └─ ...
  │   └─ finish = "stop" (子会话完成)
  │   ↓
  │   返回结果
  │   ↓
  ├─ 将结果写入 tool part
  └─ continue (回到循环开始)
  ↓
Main Session Loop (step N+2)
  ├─ 读取消息历史（包含 subtask 结果）
  ├─ 调用 LLM（LLM 看到 subtask 结果）
  └─ 继续执行
```

### 关键特性

**1. 同步等待（Synchronous Wait）**

```typescript
// TaskTool.execute() 是 async 函数
// await SessionPrompt.prompt() 会阻塞，直到子会话完成
const result = await SessionPrompt.prompt({ ... })
```

- **不是异步回调**：父会话会阻塞等待子会话完成
- **不是消息队列**：不需要轮询或监听事件
- **简单可靠**：子会话完成后，父会话自动继续

**2. 递归 Loop**

```typescript
// SessionPrompt.loop() 可以递归调用
// 父会话的 loop 调用子会话的 loop
Main loop() {
  while (true) {
    if (subtask) {
      await TaskTool.execute()  // 内部调用 Sub loop()
    }
  }
}
```

- **嵌套执行**：子会话的 loop 在父会话的 loop 内部执行
- **栈式管理**：利用 JavaScript 的调用栈管理会话层级
- **自动恢复**：子会话完成后，自动返回父会话的 loop

**3. 消息历史驱动**

```typescript
// 每轮循环都重新读取消息历史
let msgs = await MessageV2.filterCompacted(MessageV2.stream(sessionID))

// 子会话的结果写入消息历史
await Session.updatePart({
  ...part,
  state: {
    status: "completed",
    output: result.output,  // 子会话的输出
  },
})
```

- **无状态 Loop**：每轮循环都从消息历史重新构建状态
- **可恢复**：如果进程崩溃，可以从消息历史恢复
- **可审计**：所有 subtask 的输入输出都记录在消息历史中

---

## 三、决策机制：谁决定由哪个 subagent 接管

### 决策者：**LLM（通过 tool call）**

**关键代码：**

```typescript
// 文件：packages/opencode/src/tool/task.ts (line ~20)

const parameters = z.object({
  description: z.string().describe("A short (3-5 words) description of the task"),
  prompt: z.string().describe("The task for the agent to perform"),
  subagent_type: z.string().describe("The type of specialized agent to use for this task"),
  task_id: z.string().optional(),
  command: z.string().optional(),
})
```

- LLM 调用 `task` 工具时，必须指定 `subagent_type`
- **LLM 自己决定**用哪个 subagent

### 决策位置：**Tool Description（System Prompt）**

**关键代码：**

```typescript
// 文件：packages/opencode/src/tool/task.ts (line ~30)

export const TaskTool = Tool.define("task", async (ctx) => {
  // 1. 获取所有可用的 subagent
  const agents = await Agent.list().then((x) => 
    x.filter((a) => a.mode !== "primary")
  )

  // 2. 过滤权限
  const caller = ctx?.agent
  const accessibleAgents = caller
    ? agents.filter((a) => 
        PermissionNext.evaluate("task", a.name, caller.permission).action !== "deny"
      )
    : agents

  // 3. 生成 tool description（注入到 system prompt）
  const description = DESCRIPTION.replace(
    "{agents}",
    accessibleAgents
      .map((a) => 
        `- ${a.name}: ${a.description ?? "This subagent should only be called manually by the user."}`
      )
      .join("\n"),
  )
  
  return { description, parameters, execute }
})
```

**Tool Description 示例：**

```
Use this tool to delegate a task to a specialized subagent.

Available subagents:
- build: The default agent. Executes tools based on configured permissions.
- plan: Plan mode. Disallows all edit tools.
- architect: Specialized in system design and architecture decisions.
- reviewer: Specialized in code review and quality assurance.

Choose the appropriate subagent_type based on the task requirements.
```

### 决策流程

```
1. System Prompt 注入
   ├─ resolveTools() 解析所有可用工具
   ├─ TaskTool 的 description 包含所有可用 subagent
   └─ LLM 看到 tool description

2. LLM 决策
   ├─ 分析用户任务
   ├─ 判断是否需要 subagent
   ├─ 从 tool description 中选择合适的 subagent_type
   └─ 调用 task 工具

3. 权限检查
   ├─ TaskTool.execute() 检查权限
   ├─ PermissionNext.evaluate("task", subagent_type, ...)
   └─ 如果权限不足，抛出错误

4. 创建子会话
   ├─ Session.create({ parentID, ... })
   ├─ 设置子会话的 agent = subagent_type
   └─ 执行子会话
```

### 稳定性保证机制

#### 1. Agent 注册表

**文件：** `packages/opencode/src/agent/agent.ts`

```typescript
// 所有 agent 必须在配置中注册
const result: Record<string, Info> = {
  build: { name: "build", mode: "primary", ... },
  plan: { name: "plan", mode: "primary", ... },
  // 用户自定义 agent 从配置文件加载
}

// 从配置文件加载自定义 agent
for (const [name, info] of Object.entries(cfg.agent ?? {})) {
  result[name] = { ...info, name, native: false }
}
```

- **静态注册**：所有 agent 必须在启动时注册
- **类型安全**：agent 信息有 zod schema 验证
- **配置驱动**：用户可以通过配置文件添加自定义 agent

#### 2. 权限系统

```typescript
// 每个 agent 有独立的权限规则
export const Info = z.object({
  name: z.string(),
  mode: z.enum(["subagent", "primary", "all"]),
  permission: PermissionNext.Ruleset,  // 权限规则
  // ...
})

// 调用 subagent 前检查权限
await ctx.ask({
  permission: "task",
  patterns: [params.subagent_type],
  metadata: { ... },
})
```

- **最小权限**：每个 agent 只能访问允许的工具
- **嵌套权限**：subagent 的权限 = agent 权限 ∩ session 权限
- **用户确认**：敏感操作需要用户批准

#### 3. Mode 隔离

```typescript
// agent 有三种 mode
mode: z.enum(["subagent", "primary", "all"])

// 只有 mode !== "primary" 的 agent 可以作为 subagent
const agents = await Agent.list().then((x) => 
  x.filter((a) => a.mode !== "primary")
)
```

- **primary agent**：只能作为主会话（build, plan）
- **subagent**：只能作为子会话
- **all**：两者都可以

#### 4. 错误处理

```typescript
// 如果 subagent 不存在
const agent = await Agent.get(params.subagent_type)
if (!agent) 
  throw new Error(`Unknown agent type: ${params.subagent_type}`)

// 如果 subagent 执行失败
const result = await taskTool.execute(taskArgs, taskCtx).catch((error) => {
  executionError = error
  log.error("subtask execution failed", { error, agent, description })
  return undefined
})

// 将错误写入消息历史
if (!result) {
  await Session.updatePart({
    ...part,
    state: {
      status: "error",
      error: `Tool execution failed: ${executionError.message}`,
    },
  })
}
```

- **优雅降级**：subagent 失败不会导致主会话崩溃
- **错误记录**：所有错误都记录在消息历史中
- **可恢复**：主会话可以看到错误，决定如何处理

#### 5. 防止无限递归

```typescript
// 子会话默认禁止调用 task 工具
const hasTaskPermission = agent.permission.some((rule) => 
  rule.permission === "task"
)

await Session.create({
  parentID: ctx.sessionID,
  permission: [
    ...(hasTaskPermission ? [] : [
      {
        permission: "task",
        pattern: "*",
        action: "deny",  // 禁止子会话再派发 subagent
      },
    ]),
  ],
})
```

- **默认禁止嵌套**：subagent 默认不能再派发 subagent
- **显式允许**：只有明确配置了 `task` 权限的 agent 才能嵌套
- **防止死循环**：避免 A → B → A 的循环派发

---

## 四、核心设计模式总结

### 1. Two-Phase Dispatch（两阶段派发）

```
Phase 1: Decision (LLM)
  └─ LLM 调用 task 工具 → 创建 subtask part

Phase 2: Execution (Loop)
  └─ Loop 检测 subtask part → 执行 TaskTool → 等待完成
```

**优势：**
- 解耦决策和执行
- 可中断、可恢复
- 消息历史完整

### 2. Synchronous Recursion（同步递归）

```
Main loop() {
  await TaskTool.execute() {
    await Sub loop() {
      // 子会话的 loop
    }
  }
}
```

**优势：**
- 简单可靠（不需要异步回调）
- 利用调用栈管理层级
- 自动恢复到父会话

### 3. Message History Driven（消息历史驱动）

```
每轮循环：
1. 读取消息历史
2. 分析状态（是否有 pending subtask）
3. 执行操作（LLM 或 subtask）
4. 写入消息历史
5. 回到步骤 1
```

**优势：**
- 无状态 loop（可恢复）
- 可审计（所有操作都记录）
- 可回放（重现执行过程）

### 4. LLM-Driven Routing（LLM 驱动路由）

```
System Prompt 注入 agent 列表
  ↓
LLM 分析任务
  ↓
LLM 选择 subagent_type
  ↓
调用 task 工具
```

**优势：**
- 灵活（LLM 自己决策）
- 可扩展（添加新 agent 只需更新配置）
- 智能（LLM 可以根据上下文选择）

### 5. Permission-Based Isolation（权限隔离）

```
每个 agent 有独立的权限规则
  ↓
子会话继承父会话权限（交集）
  ↓
默认禁止嵌套派发
```

**优势：**
- 最小权限原则
- 防止越权
- 防止无限递归

---

## 五、与 oh-my-openagent / OpenClaw 对比

| 维度 | OpenCode | oh-my-openagent | OpenClaw |
|------|----------|-----------------|----------|
| **Loop 位置** | SessionPrompt.loop() | Atlas 协调 | sessions_spawn |
| **拆解时机** | 两阶段（LLM 决策 + Loop 执行） | Atlas 读计划后动态决策 | Main 显式调用 |
| **同步/异步** | 同步递归（await） | 同步任务 + 后台任务 | sessions_send 回传 |
| **决策者** | LLM（通过 tool call） | Atlas（读计划） | Main（显式指定） |
| **决策位置** | Tool description（system prompt） | 计划文件 | 任务输入 |
| **稳定性保证** | 注册表 + 权限 + mode 隔离 | Category 系统 + 回退链 | 协议 + 治理规则 |
| **嵌套支持** | 默认禁止，显式允许 | 支持 | 支持 |
| **消息历史** | 完整记录（包含 subtask） | Notepad 系统 | 落盘 + 回传摘要 |

### 核心差异

**OpenCode：**
- **LLM 驱动**：LLM 自己决定何时、用哪个 subagent
- **同步递归**：简单可靠，利用调用栈
- **消息历史驱动**：无状态 loop，可恢复
- **权限隔离**：防止越权和无限递归

**oh-my-openagent：**
- **计划驱动**：Atlas 读计划后动态决策
- **智慧积累**：learnings 在任务间传递
- **Category 系统**：语义化任务分类

**OpenClaw：**
- **协议驱动**：强制回传协议，防止消息丢失
- **Main-Owned**：项目选择、对外发布由 Main 控制
- **安全优先**：最小权限 + 治理规则

---

## 六、关键代码位置

| 功能 | 文件 | 行数 |
|------|------|------|
| 主 Loop | `packages/opencode/src/session/prompt.ts` | ~200-800 |
| Task 工具 | `packages/opencode/src/tool/task.ts` | ~30-150 |
| Agent 注册表 | `packages/opencode/src/agent/agent.ts` | ~50-150 |
| 权限系统 | `packages/opencode/src/permission/next.ts` | - |
| 消息历史 | `packages/opencode/src/session/message-v2.ts` | - |

---

## 七、总结

OpenCode 的 subagent 分发机制核心特点：

1. **两阶段派发**：LLM 决策 + Loop 执行，解耦决策和执行
2. **同步递归**：利用 await 和调用栈，简单可靠
3. **LLM 驱动路由**：LLM 自己选择 subagent，灵活智能
4. **消息历史驱动**：无状态 loop，可恢复、可审计
5. **权限隔离**：防止越权和无限递归

与 oh-my-openagent 和 OpenClaw 相比，OpenCode 更注重**简单性、可靠性、可恢复性**，适合需要灵活 LLM 驱动路由的场景。
