const plugin = require('/Users/tsgsz/.openclaw/plugins/task-dispatch/index.js').default;

const mockApi = {
  pluginConfig: {
    taskTimeout: 300000,
    maxConcurrentTasks: 10,
    maxRegistrySize: 1000
  },
  runtime: {
    subagent: {
      run: async ({ sessionKey, message }) => {
        console.log(`Mock subagent.run: ${sessionKey} - ${message}`);
        return { runId: 'mock-run-123' };
      },
      waitForRun: async ({ runId }) => {
        console.log(`Mock waitForRun: ${runId}`);
      },
      getSessionMessages: async ({ sessionKey }) => {
        return { messages: [{ role: 'assistant', content: 'Mock response: 2+2=4' }] };
      }
    }
  },
  registerTool: (tool) => {
    console.log(`✅ Tool registered: ${tool.name}`);
    mockApi.tools = mockApi.tools || {};
    mockApi.tools[tool.name] = tool;
  }
};

console.log('=== Task Dispatch Plugin Direct Test ===\n');

plugin.register(mockApi);

console.log('\n=== Test 1: task_check (empty) ===');
mockApi.tools.task_check.execute('call-1', {}).then(result => {
  console.log('Result:', result);
  
  console.log('\n=== Test 2: task_sync ===');
  return mockApi.tools.task_sync.execute('call-2', {
    agent: 'professor',
    task: 'what is 2+2?'
  });
}).then(result => {
  console.log('Result:', result);
  
  console.log('\n✅ All tests passed!');
}).catch(err => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});
