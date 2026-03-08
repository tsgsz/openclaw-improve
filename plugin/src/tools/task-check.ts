import { TaskCheckParams } from '../types';
import { TaskRegistry } from '../registry/task-registry';

export function createTaskCheckTool(registry: TaskRegistry) {
  return {
    name: 'task_check',
    description: 'Query task status and results',
    parameters: {
      type: 'object',
      properties: {
        task_id: { type: 'string', description: 'Task ID to check (omit for all tasks)' }
      }
    },
    async execute(toolCallId: string, params?: TaskCheckParams) {
      if (params?.task_id) {
        const task = registry.get(params.task_id);
        if (!task) {
          return { type: 'text', text: "Task not found" };
        }
        return { type: 'text', text: JSON.stringify(task, null, 2) };
      }

      const allTasks = registry.getAll().map(task => ({
        task_id: task.taskId,
        status: task.status,
        agent: task.agent,
        result: task.result,
        error: task.error
      }));
      return { type: 'text', text: JSON.stringify(allTasks, null, 2) };
    }
  };
}
