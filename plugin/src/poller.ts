import { TaskRegistry } from './registry/task-registry';

export class TaskPoller {
  private intervalId: NodeJS.Timeout | null = null;
  private registry: TaskRegistry;
  private api: any;
  private pollInterval: number;

  constructor(api: any, registry: TaskRegistry, pollInterval: number = 10000) {
    this.api = api;
    this.registry = registry;
    this.pollInterval = pollInterval;
  }

  start() {
    if (this.intervalId) return;
    
    this.intervalId = setInterval(() => {
      this.checkTasks();
    }, this.pollInterval);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  private async checkTasks() {
    const tasks = this.registry.getAll();
    
    for (const task of tasks) {
      if (task.status !== 'running') continue;
      
      try {
        const messages = await this.api.runtime.subagent.getSessionMessages({
          sessionKey: task.sessionKey,
          limit: 10
        });
        
        const lastMsg = messages.messages?.[messages.messages.length - 1];
        if (lastMsg?.role === 'assistant') {
          task.status = 'completed';
          task.result = lastMsg.content;
        }
      } catch (error: any) {
        if (error.message?.includes('not found')) {
          task.status = 'failed';
          task.error = 'Session not found';
        }
      }
    }
  }
}
