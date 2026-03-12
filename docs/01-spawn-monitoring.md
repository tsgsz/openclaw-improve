# Spawn 监控系统

## 目标

在 subagent spawn 时强制选择项目和 ETA，并监控运行状态。

## 数据结构

### runtime.json

位置: `~/.openclaw/subagents/runtime.json`

```json
{
  "tasks": {
    "run_abc123": {
      "sessionKey": "agent:orchestrator:xyz",
      "project": "my-app",
      "eta": 300,
      "timeout": 600,
      "startTime": 1710072000000,
      "extensions": 0,
      "currentETA": 300
    }
  }
}
```

### 现有的 runs.json

位置: `~/.openclaw/subagents/runs.json`

```json
{
  "version": 2,
  "runs": {
    "run_abc123": {
      "sessionKey": "agent:orchestrator:xyz",
      "pid": 12345,
      "startedAt": 1710072000000
    }
  }
}
```

**设计决策**: 
- `runs.json` 由 openclaw 原生管理，不修改
- `runtime.json` 新增，存储扩展信息（项目、ETA）
- 通过 runId 关联两个文件

## Hook 实现

### 可用的 Hook 事件

OpenClaw 提供两套 Hook 系统：

#### Plugin Hooks（推荐用于扩展）
- `subagent_spawning` - spawn 之前（可阻止 spawn）
- `subagent_spawned` - spawn 成功后
- `subagent_delivery_target` - 决定 ANNOUNCE 发送目标
- `subagent_ended` - subagent 结束时
- `message_received` - 消息接收时
- `before_tool_call` / `after_tool_call` - 工具调用前后

#### Internal Hooks（内置事件系统）
- `message:preprocessed` - 消息预处理完成
- `command:new` - 新命令
- `session:compact:before/after` - 会话压缩前后

### Hook: spawn-monitor

位置: `~/.openclaw/plugins/spawn-monitor/`

**使用 Plugin Hook**: `subagent_spawning`

功能: 
1. 强制选择项目
2. 记录 ETA 到 runtime.json
3. 验证 workspaceDir 参数

```typescript
// plugin.ts
export function onLoad(registry: PluginRegistry) {
  registry.registerHook({
    name: "subagent_spawning",
    handler: async (event, context) => {
      // 检查项目选择
      const project = extractProject(event);
      if (!project) {
        throw new Error("Must specify project before spawning");
      }
      
      // 记录到 runtime.json
      await recordSpawnRuntime({
        runId: event.childRunId,
        project,
        eta: event.params.runTimeoutSeconds || 300,
      });
    }
  });
}
```

### Hook: project-tagger

位置: `~/.openclaw/plugins/project-tagger/`

**使用 Plugin Hook**: `message_received`

功能: 为消息添加项目标签

```typescript
export function onLoad(registry: PluginRegistry) {
  registry.registerHook({
    name: "message_received",
    handler: async (event, context) => {
      const project = await matchProject(event.message);
      if (project) {
        event.message = `<project: ${project}>\n${event.message}`;
      }
    }
  });
}
```

---

## 监控脚本

### runtime-monitor.py

**位置**: `~/.openclaw/bin/runtime-monitor.py`

**功能**: 轮询 runtime.json，检查超时任务

**运行方式**: Cron 定时任务（每分钟）

```bash
# 添加到 crontab
* * * * * python3 ~/.openclaw/bin/runtime-monitor.py check
```

**检查逻辑**:
1. 读取 `~/.openclaw/subagents/runs.json` 和 `runtime.json`
2. 对比找出超时任务：
   - `currentTime > startTime + currentETA` → 超时
   - `runId` 在 runtime.json 但不在 runs.json → 已结束
3. 对于超时任务，spawn watchdog 进行检查：
   ```bash
   openclaw agent --message "检查 session <sessionKey> 的状态，判断是否完成/失败/需要延长。runId: <runId>" \
     --agent watchdog
   ```

**不做的事情**:
- 不做非标判断（交给 watchdog）
- 不直接修改 runtime.json（由 watchdog 修改）
- 不发送通知（由 watchdog 发送）

**职责分工**:
- **脚本**: 标准化比较（时间、状态）
- **watchdog**: 非标判断（看对话记录，判断实际情况）
