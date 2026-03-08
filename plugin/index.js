"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const task_registry_1 = require("./registry/task-registry");
const task_sync_1 = require("./tools/task-sync");
const task_async_1 = require("./tools/task-async");
const task_check_1 = require("./tools/task-check");
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
    register(api) {
        const config = api.pluginConfig || {
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
        const registry = new task_registry_1.TaskRegistry(config.maxRegistrySize);
        api.registerTool((0, task_sync_1.createTaskSyncTool)(api, config));
        api.registerTool((0, task_async_1.createTaskAsyncTool)(api, registry));
        api.registerTool((0, task_check_1.createTaskCheckTool)(registry));
    }
};
exports.default = plugin;
//# sourceMappingURL=index.js.map