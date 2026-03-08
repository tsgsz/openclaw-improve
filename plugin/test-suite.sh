#!/bin/bash
set -e

echo "=== Task Dispatch Plugin Test Suite ==="
echo ""

echo "Test 1: Check plugin loaded"
openclaw plugins info task-dispatch | grep "Tools: task_sync, task_async, task_check" && echo "✅ Plugin loaded" || echo "❌ Plugin not loaded"

echo ""
echo "Test 2: Start OpenClaw TUI for manual testing"
echo "Run these commands in TUI:"
echo "  1. Use task_check tool to verify empty registry"
echo "  2. Use task_async tool with test task"
echo "  3. Use task_check to verify task created"
echo ""
echo "Starting TUI in 3 seconds..."
sleep 3

openclaw tui --session test-task-dispatch
