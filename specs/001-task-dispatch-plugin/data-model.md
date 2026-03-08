# Data Model: OpenClaw Task Dispatch Plugin

**Date**: 2026-03-08

## Core Entities

### Task

Represents a single task execution (sync or async).

**Fields**:
- `taskId`: string - Unique identifier (format: `task-{timestamp}-{random}`)
- `sessionKey`: string - OpenClaw session key for tracking
- `runId`: string | undefined - OpenClaw run ID (for regular subagents)
- `status`: TaskStatus - Current execution state
- `agent`: string - Target agent name (e.g., "professor", "coder")
- `result`: string | undefined - Final result from subagent
- `error`: string | undefined - Error message if failed
- `createdAt`: number - Timestamp when task was created
- `completedAt`: number | undefined - Timestamp when task completed

**Validation Rules**:
- taskId must be unique across all tasks
- status must be one of: "running" | "completed" | "failed" | "timeout"
- agent must be non-empty string
- result and error are mutually exclusive (only one can be set)

**State Transitions**:
```
running → completed (on success)
running → failed (on error)
running → timeout (on timeout)
```

---

### TaskRegistry

In-memory storage for all tasks.

**Structure**: Map<string, Task>
- Key: taskId
- Value: Task object

**Operations**:
- `set(taskId, task)`: Add or update task
- `get(taskId)`: Retrieve task by ID
- `getAll()`: Retrieve all tasks
- `delete(taskId)`: Remove task (for LRU eviction)
- `size`: Current number of tasks

**Constraints**:
- Maximum size: 1000 entries (configurable)
- LRU eviction: Remove oldest completed task when limit exceeded
- Running tasks never evicted until completion

---

### PluginConfig

Plugin configuration from openclaw.json.

**Fields**:
- `taskTimeout`: number - Default timeout in milliseconds (default: 300000)
- `maxConcurrentTasks`: number - Maximum concurrent async tasks (default: 10)
- `maxRegistrySize`: number - Maximum task registry entries (default: 1000)

**Validation Rules**:
- taskTimeout must be > 0
- maxConcurrentTasks must be > 0
- maxRegistrySize must be >= maxConcurrentTasks

---

## Type Definitions

```typescript
type TaskStatus = "running" | "completed" | "failed" | "timeout";

interface Task {
  taskId: string;
  sessionKey: string;
  runId?: string;
  status: TaskStatus;
  agent: string;
  result?: string;
  error?: string;
  createdAt: number;
  completedAt?: number;
}

interface PluginConfig {
  taskTimeout: number;
  maxConcurrentTasks: number;
  maxRegistrySize: number;
}

interface TaskSyncParams {
  agent: string;
  task: string;
  timeout_ms?: number;
}

interface TaskAsyncParams {
  agent: string;
  task: string;
  project_root?: string;
  model?: string;
  timeout_ms?: number;
}

interface TaskCheckParams {
  task_id?: string;
}
```

---

## Relationships

- TaskRegistry contains multiple Task entities
- Each Task is associated with one OpenClaw session (via sessionKey)
- PluginConfig governs TaskRegistry behavior (size limits, timeouts)
