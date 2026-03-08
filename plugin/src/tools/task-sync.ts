import { TaskSyncParams } from '../types';

export function createTaskSyncTool(api: any, config: any) {
  return {
    name: 'task_sync',
    description: 'Synchronous task delegation with guaranteed result delivery',
    parameters: {
      type: 'object',
      properties: {
        agent: { type: 'string', description: 'Target agent ID' },
        task: { type: 'string', description: 'Task description' },
        timeout_ms: { type: 'number', description: 'Timeout in milliseconds' }
      },
      required: ['agent', 'task']
    },
    async execute(toolCallId: string, params: TaskSyncParams) {
    const { agent, task, timeout_ms = config.taskTimeout } = params;

    if (!agent || typeof agent !== 'string' || agent.trim() === '') {
      return { type: 'text', text: "Error: agent must be a non-empty string" };
    }

    if (!task || typeof task !== 'string' || task.trim() === '') {
      return { type: 'text', text: "Error: task must be a non-empty string" };
    }

    const sessionKey = `sync-${Date.now()}`;

    try {
      const { runId } = await api.runtime.subagent.run({
        sessionKey,
        message: task,
        deliver: false
      });

      await api.runtime.subagent.waitForRun({
        runId,
        timeoutMs: timeout_ms
      });

      const { messages } = await api.runtime.subagent.getSessionMessages({
        sessionKey,
        limit: 100
      });

      const result = extractResult(messages);
      return { type: 'text', text: result };
    } catch (error: any) {
      if (error.message?.includes('timeout')) {
        return { type: 'text', text: `Error: Task timeout after ${timeout_ms}ms` };
      }
      return { type: 'text', text: `Error: ${error.message}` };
    }
    }
  };
}

function extractResult(messages: any[]): string {
  const reversed = [...messages].reverse();
  const lastAssistant = reversed.find(m => m.role === "assistant");
  return lastAssistant?.content || "No result";
}
