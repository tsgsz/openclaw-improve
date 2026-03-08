const plugin = require('/Users/tsgsz/.openclaw/plugins/task-dispatch/index.js').default;

let testsPassed = 0;
let testsFailed = 0;

const mockApi = {
  pluginConfig: { taskTimeout: 5000, maxConcurrentTasks: 10, maxRegistrySize: 1000 },
  runtime: {
    subagent: {
      run: async ({ sessionKey, message }) => ({ runId: `run-${Date.now()}` }),
      waitForRun: async () => {},
      getSessionMessages: async () => ({ messages: [{ role: 'assistant', content: 'Test result' }] })
    },
    sessions_spawn: async () => {}
  },
  registerTool: (tool) => {
    mockApi.tools = mockApi.tools || {};
    mockApi.tools[tool.name] = tool;
  }
};

async function test(name, fn) {
  try {
    await fn();
    console.log(`✅ ${name}`);
    testsPassed++;
  } catch (err) {
    console.log(`❌ ${name}: ${err.message}`);
    testsFailed++;
  }
}

async function runTests() {
  console.log('=== Task Dispatch Plugin Test Suite ===\n');
  
  plugin.register(mockApi);
  
  await test('Plugin registers 3 tools', () => {
    if (!mockApi.tools.task_sync) throw new Error('task_sync not registered');
    if (!mockApi.tools.task_async) throw new Error('task_async not registered');
    if (!mockApi.tools.task_check) throw new Error('task_check not registered');
  });
  
  await test('task_check returns empty array initially', async () => {
    const result = await mockApi.tools.task_check.execute('c1', {});
    if (result.text !== '[]') throw new Error(`Expected [], got ${result.text}`);
  });
  
  await test('task_sync validates agent parameter', async () => {
    const result = await mockApi.tools.task_sync.execute('c2', { task: 'test' });
    if (!result.text.includes('Error')) throw new Error('Should validate agent');
  });
  
  await test('task_sync validates task parameter', async () => {
    const result = await mockApi.tools.task_sync.execute('c3', { agent: 'test' });
    if (!result.text.includes('Error')) throw new Error('Should validate task');
  });
  
  await test('task_sync executes successfully', async () => {
    const result = await mockApi.tools.task_sync.execute('c4', { agent: 'professor', task: 'test' });
    if (result.text.includes('Error')) throw new Error(result.text);
  });
  
  await test('task_async validates parameters', async () => {
    const result = await mockApi.tools.task_async.execute('c5', { task: 'test' });
    if (!result.text.includes('Error')) throw new Error('Should validate agent');
  });
  
  await test('task_async creates task', async () => {
    const result = await mockApi.tools.task_async.execute('c6', { agent: 'professor', task: 'test' });
    if (!result.text.includes('Task started:')) throw new Error('Should start task');
  });
  
  console.log(`\n=== Results: ${testsPassed} passed, ${testsFailed} failed ===`);
  process.exit(testsFailed > 0 ? 1 : 0);
}

runTests();
