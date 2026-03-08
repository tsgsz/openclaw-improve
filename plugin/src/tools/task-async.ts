import { TaskAsyncParams } from '../types';
import { TaskRegistry } from '../registry/task-registry';

export function createTaskAsyncTool(api: any, registry: TaskRegistry) {
  return {
    name: 'task_async',
    description: 'Asynchronous task tracking with parallel execution support',
    parameters: {
      type: 'object',
      properties: {
        agent: { type: 'string', description: 'Target agent ID' },
        task: { type: 'string', description: 'Task description' },
        project_root: { type: 'string', description: 'Project root path for coder agent' },
        model: { type: 'string', description: 'Model override' },
        timeout_ms: { type: 'number', description: 'Timeout in milliseconds' }
      },
      required: ['agent', 'task']
    },
    async execute(toolCallId: string, params: TaskAsyncParams) {
    const { agent, task, project_root, model, timeout_ms } = params;

    if (!agent || typeof agent !== 'string' || agent.trim() === '') {
      return { type: 'text', text: "Error: agent must be a non-empty string" };
    }

    if (!task || typeof task !== 'string' || task.trim() === '') {
      return { type: 'text', text: "Error: task must be a non-empty string" };
    }

    const taskId = `task-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const sessionKey = `async-${taskId}`;

    try {
      if (agent === "coder") {
        await api.runtime.sessions_spawn({
          runtime: "acp",
          agentId: "opencode",
          task,
          cwd: project_root,
          model,
          runTimeoutSeconds: timeout_ms ? timeout_ms / 1000 : undefined
        });

        registry.set(taskId, {
          taskId,
          sessionKey,
          status: "running",
          agent,
          createdAt: Date.now()
        });
      } else {
        const { runId } = await api.runtime.subagent.run({
          sessionKey,
          message: task,
          deliver: true
        });

        registry.set(taskId, {
          taskId,
          sessionKey,
          runId,
          status: "running",
          agent,
          createdAt: Date.now()
        });
      }

      return { type: 'text', text: `Task started: ${taskId}` };
    } catch (error: any) {
      return { type: 'text', text: `Error: ${error.message}` };
    }
    }
  };
}
