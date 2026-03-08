#!/bin/bash
# Test script for task-dispatch plugin

echo "=== Task Dispatch Plugin Test ==="
echo ""
echo "Plugin location: ~/.openclaw/plugins/task-dispatch"
echo "Build status:"
ls -la ~/.openclaw/plugins/task-dispatch/dist/index.js 2>/dev/null && echo "✓ Built successfully" || echo "✗ Build missing"
echo ""
echo "Configuration status:"
grep -q "task-dispatch" ~/.openclaw/openclaw.json && echo "✓ Plugin configured in openclaw.json" || echo "✗ Not configured"
echo ""
echo "=== Manual Testing Instructions ==="
echo ""
echo "1. Restart OpenClaw to load the plugin"
echo "2. Test sync task (as orchestrator):"
echo '   task_sync({ agent: "professor", task: "test" })'
echo ""
echo "3. Test async task:"
echo '   task_async({ agent: "professor", task: "test" })'
echo '   task_check()'
echo ""
echo "4. Check test scenarios:"
echo "   cat ~/.openclaw/plugins/task-dispatch/tests/manual/test-scenarios.md"
