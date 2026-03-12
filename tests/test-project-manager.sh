#!/bin/bash
set -e

echo "==> 测试项目管理脚本"

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_MANAGER="${TEST_DIR}/../src/scripts/project-manager.py"

export HOME="${TEST_DIR}/test-home"
mkdir -p "${HOME}"

echo "测试 1: 创建永久项目"
python3 "${PROJECT_MANAGER}" create test-perm permanent "Test permanent project"

echo "测试 2: 创建临时项目"
python3 "${PROJECT_MANAGER}" create test-tmp temporary "Test temp project"

echo "测试 3: 列出项目"
python3 "${PROJECT_MANAGER}" list --json

echo "测试 4: 获取项目详情"
python3 "${PROJECT_MANAGER}" get test-perm

echo "测试 5: 删除项目"
python3 "${PROJECT_MANAGER}" delete test-tmp

echo "==> 所有测试通过"
rm -rf "${HOME}"
