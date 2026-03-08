export type TaskStatus = "running" | "completed" | "failed" | "timeout";

export interface Task {
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

export interface PluginConfig {
  taskTimeout: number;
  maxConcurrentTasks: number;
  maxRegistrySize: number;
}

export interface TaskSyncParams {
  agent: string;
  task: string;
  timeout_ms?: number;
}

export interface TaskAsyncParams {
  agent: string;
  task: string;
  project_root?: string;
  model?: string;
  timeout_ms?: number;
}

export interface TaskCheckParams {
  task_id?: string;
}
