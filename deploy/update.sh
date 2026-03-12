#!/bin/bash
# Openclaw 增强形态 - 更新脚本

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 更新 Openclaw 增强形态"

# 重新运行安装脚本
"${PROJECT_ROOT}/deploy/install.sh"

echo "==> 更新完成"
