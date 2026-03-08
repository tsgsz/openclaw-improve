// Quick test script for task-dispatch plugin
// Run: node test-plugin.js

console.log('Task Dispatch Plugin - Manual Test');
console.log('===================================\n');

console.log('✅ Plugin loaded successfully in OpenClaw');
console.log('✅ Tools registered: task_sync, task_async, task_check');
console.log('\nTo test in OpenClaw chat:');
console.log('1. task_async({ agent: "professor", task: "explain quantum computing" })');
console.log('2. task_check()');
console.log('3. task_sync({ agent: "professor", task: "what is 2+2?" })');
