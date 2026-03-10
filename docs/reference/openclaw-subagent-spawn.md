# Subagent Spawn 机制参考文档

本文档整理了 OpenClaw 中 subagent spawn 的核心机制，包括注册、ANNOUNCE、hooks 和工作目录管理。

---

## 1. Spawn 参数

### 主要参数 (`SpawnSubagentParams`)

**位置**: `src/agents/subagent-spawn.ts:46-65`

```typescript
{
  task: string;                    // 必需：任务描述
  label?: string;                  // 可选：任务标签（用于标识和显示）
  agentId?: string;                // 可选：指定 agent ID
  model?: string;                  // 可选：指定模型 (格式: "provider/model")
  thinking?: string;               // 可选：thinking level
  runTimeoutSeconds?: number;      // 可选：运行超时（秒）
  thread?: boolean;                // 可选：是否绑定线程
  mode?: "run" | "session";        // 可选：运行模式
  cleanup?: "delete" | "keep";     // 可选：完成后清理策略
  sandbox?: "inherit" | "require"; // 可选：沙箱模式
  expectsCompletionMessage?: boolean; // 可选：是否期待完成消息
  attachments?: Array<{            // 可选：附件
    name: string;
    content: string;
    encoding?: "utf8" | "base64";
    mimeType?: string;
  }>;
  attachMountPath?: string;        // 可选：附件挂载路径
}
```

### 上下文参数 (`SpawnSubagentContext`)

**位置**: `src/agents/subagent-spawn.ts:67-79`

```typescript
{
  agentSessionKey?: string;
  agentChannel?: string;
  agentAccountId?: string;
  agentTo?: string;
  agentThreadId?: string | number;
  agentGroupId?: string | null;
  agentGroupChannel?: string | null;
  agentGroupSpace?: string | null;
  requesterAgentIdOverride?: string;
  workspaceDir?: string;           // 工作目录（重要！）
}
```

---

## 2. 关键参数详解

### 2.1 `label` 参数

**作用**：给 subagent 任务添加人类可读的标签

**影响**：
- 更新子会话的 `label` 字段
- 在 ANNOUNCE 消息中显示
- 用于会话查找和识别

**代码位置**: `src/agents/subagent-announce.ts:1457-1461`

```typescript
if (params.label) {
  await patchSessionLabel({
    params: { key: params.childSessionKey, label: params.label },
  });
}
```

### 2.2 `expectsCompletionMessage` 参数

**作用**：控制 ANNOUNCE 消息的格式和行为

**代码位置**: `src/agents/subagent-announce.ts:1016-1025`

```typescript
function buildAnnounceReplyInstruction(params: {
  requesterIsSubagent: boolean;
  announceType: SubagentAnnounceType;
  expectsCompletionMessage?: boolean;
}): string {
  if (params.requesterIsSubagent) {
    return `Convert this completion into a concise internal orchestration update...`;
  }
  
  // expectsCompletionMessage = true
  if (params.expectsCompletionMessage) {
    return `A completed task is ready for user delivery. 
            Convert the result into your normal assistant voice...`;
  }
  
  // expectsCompletionMessage = false (默认)
  return `A completed task is ready for user delivery. 
          Reply ONLY: ${SILENT_REPLY_TOKEN} if this exact result 
          was already delivered...`;
}
```

**区别**：
- `true`: 强制发送完成消息，不允许跳过
- `false`: 允许跳过重复消息（可返回 SILENT_REPLY_TOKEN）

### 2.3 `workspaceDir` 参数

**作用**：指定 subagent 的文件系统工作目录

**继承规则**: `src/agents/spawned-context.ts:59-74`

```typescript
export function resolveSpawnedWorkspaceInheritance(params: {
  config: OpenClawConfig;
  requesterSessionKey?: string;
  explicitWorkspaceDir?: string | null;
}): string | undefined {
  // 1. 优先使用显式指定的 workspaceDir
  const explicit = normalizeOptionalText(params.explicitWorkspaceDir);
  if (explicit) {
    return explicit;
  }
  
  // 2. 否则继承父 agent 的 workspace
  const requesterAgentId = params.requesterSessionKey
    ? parseAgentSessionKey(params.requesterSessionKey)?.agentId
    : undefined;
  return requesterAgentId
    ? resolveAgentWorkspaceDir(params.config, normalizeAgentId(requesterAgentId))
    : undefined;
}
```

**使用示例**：

```typescript
// 显式指定工作目录
await spawnSubagent(
  { task: "Analyze code" },
  { workspaceDir: "/path/to/project" }
);

// 继承父 agent 的工作目录（默认）
await spawnSubagent(
  { task: "Analyze code" },
  { agentSessionKey: parentSessionKey }
);
```

---

## 3. Subagent 注册机制

### 3.1 注册入口

**位置**: `src/agents/subagent-spawn.ts:643-660`

```typescript
registerSubagentRun({
  runId: childRunId,
  childSessionKey,
  requesterSessionKey: requesterInternalKey,
  requesterOrigin,
  requesterDisplayKey,
  task,
  cleanup,
  label: label || undefined,
  model: resolvedModel,
  workspaceDir: spawnedMetadata.workspaceDir,
  runTimeoutSeconds,
  expectsCompletionMessage,
  spawnMode,
  attachmentsDir: attachmentAbsDir,
  attachmentsRootDir: attachmentRootDir,
  retainAttachmentsOnKeep: retainOnSessionKeep,
});
```

### 3.2 内存注册

**位置**: `src/agents/subagent-registry.ts:64 + 1173-1197`

```typescript
// 全局内存 Map
const subagentRuns = new Map<string, SubagentRunRecord>();

// 注册函数
export function registerSubagentRun(params: {...}) {
  const now = Date.now();
  
  // 存入内存 Map
  subagentRuns.set(params.runId, {
    runId: params.runId,
    childSessionKey: params.childSessionKey,
    requesterSessionKey: params.requesterSessionKey,
    requesterOrigin,
    requesterDisplayKey: params.requesterDisplayKey,
    task: params.task,
    cleanup: params.cleanup,
    expectsCompletionMessage: params.expectsCompletionMessage,
    spawnMode,
    label: params.label,
    model: params.model,
    workspaceDir: params.workspaceDir,  // ← 保存工作目录
    runTimeoutSeconds,
    createdAt: now,
    startedAt: now,
    archiveAtMs,
    cleanupHandled: false,
    // ...
  });
  
  ensureListener();
  persistSubagentRuns();  // 立即持久化到磁盘
}
```

### 3.3 磁盘持久化

**文件路径**: `~/.openclaw/state/subagents/runs.json`

**代码位置**: `src/agents/subagent-registry.store.ts:44-46`

```typescript
export function resolveSubagentRegistryPath(): string {
  return path.join(
    resolveSubagentStateDir(process.env), 
    "subagents", 
    "runs.json"
  );
}
```

**持久化逻辑**: `src/agents/subagent-registry-state.ts:7-13`

```typescript
export function persistSubagentRunsToDisk(runs: Map<string, SubagentRunRecord>) {
  try {
    saveSubagentRegistryToDisk(runs);  // 写入 JSON 文件
  } catch {
    // ignore persistence failures
  }
}
```

### 3.4 JSON 格式示例

```json
{
  "version": 2,
  "runs": {
    "run_abc123": {
      "runId": "run_abc123",
      "childSessionKey": "agent:myagent:session123",
      "requesterSessionKey": "agent:parent:session456",
      "task": "Analyze the code",
      "label": "Code Analysis",
      "cleanup": "keep",
      "expectsCompletionMessage": true,
      "spawnMode": "run",
      "workspaceDir": "/path/to/project",
      "createdAt": 1234567890,
      "startedAt": 1234567890,
      "cleanupHandled": false
    }
  }
}
```

---

## 4. ANNOUNCE 机制

### 4.1 核心流程

```
1. Subagent 完成
   └─> completeSubagentRun() (subagent-registry.ts:450)

2. 触发清理流程
   └─> startSubagentAnnounceCleanupFlow() (subagent-registry.ts:531)

3. 运行 announce 流程
   └─> runSubagentAnnounceFlow() (subagent-announce.ts)

4. 发送消息
   └─> sendAnnounce() (subagent-announce.ts:585)

5. 调用 Gateway
   └─> callGateway({ method: "agent", ... })
```

### 4.2 发送逻辑

**位置**: `src/agents/subagent-announce.ts:585-620`

```typescript
async function sendAnnounce(item: AnnounceQueueItem) {
  const cfg = loadConfig();
  const announceTimeoutMs = resolveSubagentAnnounceTimeoutMs(cfg);
  const requesterIsSubagent = isInternalAnnounceRequesterSession(item.sessionKey);
  
  await callGateway({
    method: "agent",
    params: {
      sessionKey: item.sessionKey,
      message: item.prompt,
      channel: requesterIsSubagent ? undefined : origin?.channel,
      accountId: requesterIsSubagent ? undefined : origin?.accountId,
      to: requesterIsSubagent ? undefined : origin?.to,
      threadId: requesterIsSubagent ? undefined : threadId,
      deliver: !requesterIsSubagent,  // ← 关键：控制是否发送到外部
      internalEvents: item.internalEvents,
      inputProvenance: {
        kind: "inter_session",
        sourceSessionKey: item.sourceSessionKey,
        sourceChannel: item.sourceChannel ?? INTERNAL_MESSAGE_CHANNEL,
        sourceTool: item.sourceTool ?? "subagent_announce",
      },
      idempotencyKey,
    },
    timeoutMs: announceTimeoutMs,
  });
}
```

### 4.3 ANNOUNCE_SKIP 机制

**位置**: `src/agents/tools/sessions-send-helpers.ts:8`

```typescript
const ANNOUNCE_SKIP_TOKEN = "ANNOUNCE_SKIP";

// 检查函数
function isAnnounceSkip(text?: string): boolean {
  return (text ?? "").trim() === ANNOUNCE_SKIP_TOKEN;
}
```

**配置控制**：
- 超时配置：`cfg.agents?.defaults?.subagents?.announceTimeoutMs`
- 默认值：60秒 (`DEFAULT_SUBAGENT_ANNOUNCE_TIMEOUT_MS = 60_000`)

---

## 5. Hook 系统

### 5.1 Hook 调用方式

**不是 event 驱动，是直接函数调用**：

```typescript
// Plugin Hooks (直接调用)
if (!hookRunner?.hasHooks("subagent_spawning")) {
  return { status: "error", ... };
}
await hookRunner?.runSubagentSpawned(event, context);

// Context Engine Hooks (直接调用)
const engine = await resolveContextEngine(cfg);
if (!engine.onSubagentEnded) {
  return;
}
await engine.onSubagentEnded(params);
```

### 5.2 Subagent 生命周期 Hooks

#### Hook 1: `subagent_spawning`

**时机**: spawn 之前  
**位置**: `src/agents/subagent-spawn.ts:191-195`

```typescript
if (!hookRunner?.hasHooks("subagent_spawning")) {
  return {
    status: "error",
    error: "thread=true is unavailable because no channel plugin registered subagent_spawning hooks.",
  };
}
```

#### Hook 2: `subagent_spawned`

**时机**: spawn 成功后  
**位置**: `src/agents/subagent-spawn.ts:686`

```typescript
if (hookRunner?.hasHooks("subagent_spawned")) {
  await hookRunner.runSubagentSpawned(event, context);
}
```

#### Hook 3: `subagent_delivery_target` ⭐

**时机**: 决定 ANNOUNCE 发送目标时  
**位置**: `src/agents/subagent-announce.ts:556-582`

```typescript
const hookRunner = getGlobalHookRunner();
if (!hookRunner?.hasHooks("subagent_delivery_target")) {
  return requesterOrigin;
}

try {
  const result = await hookRunner.runSubagentDeliveryTarget(
    {
      childSessionKey: params.childSessionKey,
      requesterSessionKey: params.requesterSessionKey,
      requesterOrigin,
      childRunId: params.childRunId,
      spawnMode: params.spawnMode,
      expectsCompletionMessage: params.expectsCompletionMessage,
    },
    context
  );
  
  // Hook 可以修改 delivery target
  const hookOrigin = normalizeDeliveryContext(result?.origin);
  return mergeDeliveryContext(hookOrigin, requesterOrigin);
} catch {
  return requesterOrigin;
}
```

**事件类型**: `src/plugins/types.ts:730-751`

```typescript
export type PluginHookSubagentDeliveryTargetEvent = {
  childSessionKey: string;
  requesterSessionKey: string;
  requesterOrigin?: {
    channel?: string;
    accountId?: string;
    to?: string;
    threadId?: string | number;
  };
  childRunId?: string;
  spawnMode?: "run" | "session";
  expectsCompletionMessage: boolean;
};

export type PluginHookSubagentDeliveryTargetResult = {
  origin?: {
    channel?: string;
    accountId?: string;
    to?: string;
    threadId?: string | number;
  };
};
```

#### Hook 4: `subagent_ended`

**时机**: subagent 结束时  
**位置**: `src/agents/subagent-registry-completion.ts:68`

```typescript
if (hookRunner?.hasHooks("subagent_ended")) {
  await hookRunner.runSubagentEnded(event, context);
}
```

### 5.3 Context Engine Hooks

#### `prepareSubagentSpawn`

**定义**: `src/context-engine/types.ts:153-157`

```typescript
prepareSubagentSpawn?(params: {
  parentSessionKey: string;
  childSessionKey: string;
  ttlMs?: number;
}): Promise<SubagentSpawnPreparation | undefined>;
```

**返回类型**:

```typescript
export type SubagentSpawnPreparation = {
  /** Roll back pre-spawn setup when subagent launch fails. */
  rollback: () => void | Promise<void>;
};
```

**作用**：
- 在 subagent spawn 之前准备 context engine 管理的状态
- 如果 spawn 失败，调用 `rollback()` 清理

#### `onSubagentEnded`

**定义**: `src/context-engine/types.ts:162`

```typescript
onSubagentEnded?(params: { 
  childSessionKey: string; 
  reason: SubagentEndReason  // "deleted" | "completed" | "swept" | "released"
}): Promise<void>;
```

**调用位置**: `src/agents/subagent-registry.ts:326-330`

```typescript
const engine = await resolveContextEngine(cfg);
if (!engine.onSubagentEnded) {
  return;
}
await engine.onSubagentEnded(params);
```

---

## 6. 修改 Spawn 行为的方法

### 方法 1: Plugin Hooks (推荐)

```typescript
// 在插件中注册 hook
export function onLoad(registry: PluginRegistry) {
  registry.registerHook({
    name: "subagent_spawning",
    handler: async (event, context) => {
      console.log("Spawning:", event.childSessionKey);
      // 可以修改参数或阻止 spawn
    }
  });
  
  registry.registerHook({
    name: "subagent_delivery_target",
    handler: async (event, context) => {
      // 修改 ANNOUNCE 发送目标
      return {
        origin: {
          channel: "custom-channel",
          to: "custom-target"
        }
      };
    }
  });
}
```

### 方法 2: Monkey Patch (不推荐)

```typescript
import * as registry from "./agents/subagent-registry.js";

const original = registry.registerSubagentRun;
registry.registerSubagentRun = function(params) {
  // 修改参数
  params.label = `[Modified] ${params.label}`;
  return original.call(this, params);
};
```

---

## 7. 存储的数据结构

**类型定义**: `src/agents/subagent-registry.types.ts`

```typescript
export type SubagentRunRecord = {
  runId: string;
  childSessionKey: string;
  requesterSessionKey: string;
  requesterOrigin?: DeliveryContext;
  requesterDisplayKey: string;
  task: string;
  cleanup: "delete" | "keep";
  label?: string;
  model?: string;
  workspaceDir?: string;
  runTimeoutSeconds: number;
  expectsCompletionMessage?: boolean;
  spawnMode: "run" | "session";
  
  // 时间戳
  createdAt: number;
  startedAt: number;
  endedAt?: number;
  archiveAtMs?: number;
  
  // 状态
  cleanupHandled: boolean;
  cleanupCompletedAt?: number;
  outcome?: SubagentRunOutcome;
  endedReason?: SubagentLifecycleEndedReason;
  
  // 附件
  attachmentsDir?: string;
  attachmentsRootDir?: string;
  retainAttachmentsOnKeep?: boolean;
  
  // 结果缓存
  frozenResultText?: string;
  frozenResultCapturedAt?: number;
};
```

---

## 8. 关键要点总结

1. **双重存储**: 内存 Map + 磁盘 JSON 文件 (`runs.json`)
2. **立即持久化**: 注册后立即写入磁盘
3. **跨进程可见**: 通过磁盘文件，其他进程可以读取活跃的 subagent runs
4. **Hook 系统**: 直接函数调用，不是 event 驱动
5. **工作目录**: 可以在 spawn 前通过 `workspaceDir` 指定，会保存到 `runs.json`
6. **ANNOUNCE 控制**: 通过 `expectsCompletionMessage` 和 hooks 控制
7. **扩展方式**: 推荐使用 Plugin Hooks，干净、可维护、官方支持

---

## 9. 相关文件索引

### 核心文件
- `src/agents/subagent-spawn.ts` - Spawn 入口和参数定义
- `src/agents/subagent-registry.ts` - 注册和生命周期管理
- `src/agents/subagent-announce.ts` - ANNOUNCE 消息控制
- `src/agents/spawned-context.ts` - 工作目录继承逻辑

### 存储相关
- `src/agents/subagent-registry-state.ts` - 状态管理
- `src/agents/subagent-registry.store.ts` - 磁盘持久化
- `src/agents/subagent-registry.types.ts` - 类型定义

### Hook 相关
- `src/plugins/types.ts` - Plugin Hook 类型定义
- `src/context-engine/types.ts` - Context Engine Hook 定义
- `src/plugins/hooks.ts` - Hook 运行器

---

**文档生成时间**: 2026-03-09  
**OpenClaw 版本**: 基于当前代码库分析
