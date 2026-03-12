#!/bin/bash
set -e

OPENCLAW_HOME="${OPENCLAW_HOME:-${HOME}/.openclaw}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --openclaw-home)
            OPENCLAW_HOME="$2"
            shift 2
            ;;
        --dev)
            DEV_MODE=true
            shift
            ;;
        *)
            echo "未知选项: $1"
            echo "用法: $0 [--openclaw-home PATH] [--dev]"
            exit 1
            ;;
    esac
done

ENHANCED_DIR="${OPENCLAW_HOME}/openclaw-enhanced"
SYSTEM_DIR="${ENHANCED_DIR}/system"
MANIFEST="${ENHANCED_DIR}/manifest.json"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "使用 Openclaw 目录: ${OPENCLAW_HOME}"
if [ "$DEV_MODE" = true ]; then
    echo "开发模式: 使用软链"
else
    echo "生产模式: 使用拷贝"
fi

mkdir -p "${ENHANCED_DIR}"

echo "==> 第一步：部署 src 到 system"
if [ "$DEV_MODE" = true ]; then
    ln -sf "${PROJECT_ROOT}/src" "${SYSTEM_DIR}"
else
    rm -rf "${SYSTEM_DIR}"
    cp -r "${PROJECT_ROOT}/src" "${SYSTEM_DIR}"
fi

echo "==> 第二步：从 system 软链到 openclaw 各位置"

echo "  - 软链 plugins"
for plugin_dir in "${SYSTEM_DIR}/plugins/"*; do
    [ -d "$plugin_dir" ] || continue
    openclaw plugins install --link "$plugin_dir"
done

echo "  - 软链共享 skills（所有 agents 可用）"
for skill_dir in "${SYSTEM_DIR}/skills/"*; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    target="${OPENCLAW_HOME}/skills/${skill_name}"
    ln -sf "$skill_dir" "$target"
done

echo "  - 软链 scripts"
for script_dir in "${SYSTEM_DIR}/workspace/scripts/"*; do
    [ -d "$script_dir" ] || continue
    script_name=$(basename "$script_dir")
    target="${OPENCLAW_HOME}/workspace/scripts/${script_name}"
    ln -sf "$script_dir" "$target"
done

echo "  - 添加 openclaw_enhance 章节到 AGENTS.md 和 TOOLS.md"
add_enhance_section() {
    local file=$1
    local ref_path=$2
    
    if [ -f "$file" ]; then
        if grep -q "# openclaw_enhance" "$file"; then
            sed -i.bak '/# openclaw_enhance/,$d' "$file"
            rm -f "${file}.bak"
        fi
        echo "
# openclaw_enhance

你还有一份**更高优先级的**的指南，去这里能看到 \`$ref_path\`" >> "$file"
    fi
}

add_enhance_section "${OPENCLAW_HOME}/workspace/AGENTS.md" "../openclaw-enhanced/system/workspace/AGENTS.md"

for agent in orchestrator professor systemhelper scriptproducer reviewer watchdog; do
    add_enhance_section "${OPENCLAW_HOME}/workspace/functional-workspace/${agent}/AGENTS.md" "../../openclaw-enhanced/system/workspace/functional-workspace/${agent}/AGENTS.md"
    add_enhance_section "${OPENCLAW_HOME}/workspace/functional-workspace/${agent}/TOOLS.md" "../../openclaw-enhanced/system/workspace/functional-workspace/${agent}/TOOLS.md"
done

for agent in ops game-design finance creative km; do
    add_enhance_section "${OPENCLAW_HOME}/workspace/domain-workspace/${agent}/AGENTS.md" "../../openclaw-enhanced/system/workspace/domain-workspace/${agent}/AGENTS.md"
    add_enhance_section "${OPENCLAW_HOME}/workspace/domain-workspace/${agent}/TOOLS.md" "../../openclaw-enhanced/system/workspace/domain-workspace/${agent}/TOOLS.md"
done

echo '{"version":"1.0.0","installed_at":"'$(date -Iseconds)'"}' > "$MANIFEST"

echo "==> 安装完成！"
echo "系统目录: ${SYSTEM_DIR}"
echo "清单文件: ${MANIFEST}"
