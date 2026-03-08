import { TaskRegistry } from './registry/task-registry';
import { PluginConfig } from './types';
import { createTaskSyncTool } from './tools/task-sync';
import { createTaskAsyncTool } from './tools/task-async';
import { createTaskCheckTool } from './tools/task-check';

const plugin = {
  id: 'task-dispatch',
  name: 'Task Dispatch Plugin',
  description: 'Reliable task delegation with sync/async support',
  configSchema: {
    type: 'object',
    properties: {
      taskTimeout: { type: 'number', default: 300000 },
      maxConcurrentTasks: { type: 'number', default: 10 },
      maxRegistrySize: { type: 'number', default: 1000 }
    }
  },
  register(api: any) {
    const config: PluginConfig = api.pluginConfig || {
      taskTimeout: 300000,
      maxConcurrentTasks: 10,
      maxRegistrySize: 1000
    };

    if (config.taskTimeout <= 0) {
      throw new Error('taskTimeout must be greater than 0');
    }
    if (config.maxConcurrentTasks <= 0) {
      throw new Error('maxConcurrentTasks must be greater than 0');
    }
    if (config.maxRegistrySize < config.maxConcurrentTasks) {
      throw new Error('maxRegistrySize must be >= maxConcurrentTasks');
    }

    const registry = new TaskRegistry(config.maxRegistrySize);

    api.registerTool(createTaskSyncTool(api, config));
    api.registerTool(createTaskAsyncTool(api, registry));
    api.registerTool(createTaskCheckTool(registry));
  }
};

export default plugin;
