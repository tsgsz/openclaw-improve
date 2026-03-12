#!/bin/bash
set -e

echo "==> 测试运行时监控脚本"

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_MONITOR="${TEST_DIR}/../src/scripts/runtime-monitor.py"

export HOME="${TEST_DIR}/test-home"
mkdir -p "${HOME}"

echo "测试 1: 记录 spawn"
python3 "${RUNTIME_MONITOR}" record run_123 "agent:orch:xyz" "my-app" 300 600

echo "测试 2: 检查超时"
python3 "${RUNTIME_MONITOR}" check

echo "测试 3: 更新 ETA"
python3 "${RUNTIME_MONITOR}" update-eta run_123 450

echo "测试 4: 标记完成"
python3 "${RUNTIME_MONITOR}" complete run_123

echo "==> 所有测试通过"
rm -rf "${HOME}"
