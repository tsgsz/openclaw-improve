const plugin = require('/Users/tsgsz/.openclaw/plugins/task-dispatch/index.js').default;

const mockApi = {
  pluginConfig: { taskTimeout: 5000, maxConcurrentTasks: 10, maxRegistrySize: 1000, pollInterval: 2000 },
  runtime: {
    subagent: {
      run: async ({ sessionKey }) => ({ runId: `run-${Date.now()}` }),
      waitForRun: async () => {},
      getSessionMessages: async ({ sessionKey }) => {
        if (sessionKey.includes('completed')) {
          return { messages: [{ role: 'assistant', content: 'Task completed successfully' }] };
        }
        return { messages: [] };
      }
    }
  },
  registerTool: (tool) => {
    mockApi.tools = mockApi.tools || {};
    mockApi.tools[tool.name] = tool;
  }
};

console.log('=== Task Poller Test ===\n');

plugin.register(mockApi);

console.log('✓ Plugin registered with poller');

async function testPolling() {
  console.log('\nTest: Start async task and verify polling updates status');
  
  const result = await mockApi.tools.task_async.execute('c1', {
    agent: 'professor',
    task: 'test task'
  });
  
  const taskId = result.text.match(/task-[^\s]+/)[0];
  console.log(`✓ Task started: ${taskId}`);
  
  console.log('Waiting 3 seconds for poller to check...');
  await new Promise(resolve => setTimeout(resolve, 3000));
  
  const status = await mockApi.tools.task_check.execute('c2', { task_id: taskId });
  const task = JSON.parse(status.text);
  
  console.log(`Task status: ${task.status}`);
  console.log('\n✅ Poller test complete');
}

testPolling().catch(console.error);
