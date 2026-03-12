#!/bin/bash
set -e

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> 运行所有测试"

"${TEST_DIR}/test-project-manager.sh"
"${TEST_DIR}/test-runtime-monitor.sh"

echo "==> 所有测试完成"
