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

SYSTEM_DIR="${OPENCLAW_HOME}/workspace/system/openclaw-enhance"
MANIFEST="${SYSTEM_DIR}/manifest.json"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "使用 Openclaw 目录: ${OPENCLAW_HOME}"
if [ "$DEV_MODE" = true ]; then
    echo "开发模式: 使用软链"
else
    echo "生产模式: 使用拷贝"
fi

update_manifest() {
    local key=$1
    local name=$2
    local data=$3
    
    if [ ! -f "$MANIFEST" ]; then
        echo '{"version":"1.0.0","installed_at":null,"updated_at":null,"agents":{},"skills":{},"hooks":{},"plugins":{},"backups":[]}' > "$MANIFEST"
    fi
    
    python3 -c "
import json
from datetime import datetime
with open('$MANIFEST', 'r') as f:
    m = json.load(f)
if m['installed_at'] is None:
    m['installed_at'] = datetime.now().isoformat()
m['updated_at'] = datetime.now().isoformat()
m['$key']['$name'] = $data
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
"
}

add_backup_record() {
    local path=$1
    local backup_path=$2
    
    python3 -c "
import json
from datetime import datetime
with open('$MANIFEST', 'r') as f:
    m = json.load(f)
m['backups'].append({
    'path': '$path',
    'backup_path': '$backup_path',
    'backed_up_at': datetime.now().isoformat()
})
with open('$MANIFEST', 'w') as f:
    json.dump(m, f, indent=2)
"
}

ask_overwrite() {
    local item_type=$1
    local item_name=$2
    echo "检测到已存在的 $item_type: $item_name"
    read -p "是否覆盖？(y/N) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

backup_existing() {
    local src=$1
    local type=$2
    local name=$3
    local backup_dir="${SYSTEM_DIR}/backups/${type}/${name}-${TIMESTAMP}"
    
    echo "备份 $type/$name 到 backups/..."
    mkdir -p "$(dirname "$backup_dir")"
    mv "$src" "$backup_dir"
    add_backup_record "${type}/${name}" "backups/${type}/${name}-${TIMESTAMP}"
}

echo "==> 安装 Openclaw 增强形态"
mkdir -p "${OPENCLAW_HOME}/workspace/functional-workspace"
mkdir -p "${OPENCLAW_HOME}/workspace/domain-workspace"
mkdir -p "${OPENCLAW_HOME}/workspace/projects"
mkdir -p "${OPENCLAW_HOME}/workspace/scripts"
mkdir -p "${OPENCLAW_HOME}/workspace/skills"
mkdir -p "${OPENCLAW_HOME}/hooks"
mkdir -p "${SYSTEM_DIR}"

echo "==> 部署系统配置..."
if [ "$DEV_MODE" = true ]; then
    ln -sf "${PROJECT_ROOT}/src/system/openclaw-enhance" "${SYSTEM_DIR}"
else
    cp -r "${PROJECT_ROOT}/src/system/openclaw-enhance/"* "${SYSTEM_DIR}/"
fi

echo "==> 部署 scripts..."
if [ -d "${PROJECT_ROOT}/src/scripts" ]; then
    for subdir in "${PROJECT_ROOT}/src/scripts/"*/; do
        if [ -d "$subdir" ]; then
            subdir_name=$(basename "$subdir")
            target_dir="${OPENCLAW_HOME}/workspace/scripts/${subdir_name}"
            mkdir -p "$(dirname "$target_dir")"
            
            if [ "$DEV_MODE" = true ]; then
                ln -sf "$subdir" "$target_dir"
            else
                mkdir -p "$target_dir"
                cp -r "$subdir"* "$target_dir/"
                chmod +x "$target_dir/"*.py 2>/dev/null || true
            fi
        fi
    done
fi

echo "==> 部署 skills..."
for skill_dir in "${SYSTEM_DIR}/skills/"*; do
    skill_name=$(basename "$skill_dir")
    target="${OPENCLAW_HOME}/workspace/skills/${skill_name}"
    
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if ask_overwrite "skill" "$skill_name"; then
            backup_existing "$target" "skills" "$skill_name"
            ln -sf "$skill_dir" "$target"
            update_manifest "skills" "$skill_name" '{"type":"symlink","conflict":True}'
        else
            update_manifest "skills" "$skill_name" '{"type":"skipped","conflict":True}'
        fi
    else
        ln -sf "$skill_dir" "$target"
        update_manifest "skills" "$skill_name" '{"type":"symlink","conflict":False}'
    fi
done

echo "==> 部署 plugins..."
if [ -d "${SYSTEM_DIR}/plugins" ]; then
    for plugin_dir in "${SYSTEM_DIR}/plugins/"*; do
        plugin_name=$(basename "$plugin_dir")
        if openclaw plugins list 2>/dev/null | grep -q "^${plugin_name}$"; then
            if ask_overwrite "plugin" "$plugin_name"; then
                openclaw plugins uninstall "$plugin_name" 2>/dev/null || true
                openclaw plugins install --link "$plugin_dir"
                update_manifest "plugins" "$plugin_name" '{"type":"link","conflict":True}'
            else
                update_manifest "plugins" "$plugin_name" '{"type":"skipped","conflict":True}'
            fi
        else
            update_manifest "plugins" "$plugin_name" '{"type":"link","conflict":False}'
        fi
    done
fi

echo "==> 部署 hooks..."
if [ -d "${SYSTEM_DIR}/hooks" ]; then
    for hook_dir in "${SYSTEM_DIR}/hooks/"*; do
        hook_name=$(basename "$hook_dir")
        
        if openclaw hooks list 2>/dev/null | grep -q "^${hook_name}$"; then
            if ask_overwrite "hook" "$hook_name"; then
                openclaw hooks delete "$hook_name" 2>/dev/null || true
                openclaw hooks install --link "$hook_dir"
                update_manifest "hooks" "$hook_name" '{"type":"installed","conflict":True}'
            else
                update_manifest "hooks" "$hook_name" '{"type":"skipped","conflict":True}'
            fi
        else
            update_manifest "hooks" "$hook_name" '{"type":"installed","conflict":False}'
        fi
    done
fi

echo "==> 部署 agents..."
for agent_dir in "${PROJECT_ROOT}/src/functional-workspace/"* "${PROJECT_ROOT}/src/domain-workspace/"*; do
    [ -d "$agent_dir" ] || continue
    agent_name=$(basename "$agent_dir")
    
    if [[ "$agent_dir" == *"/functional-workspace/"* ]]; then
        target_dir="${OPENCLAW_HOME}/workspace/functional-workspace/${agent_name}"
        workspace_type="functional-workspace"
    else
        target_dir="${OPENCLAW_HOME}/workspace/domain-workspace/${agent_name}"
        workspace_type="domain-workspace"
    fi
    
    mkdir -p "$target_dir"
    
    # 处理 AGENTS.md
    agents_md="$target_dir/AGENTS.md"
    agents_section="
# openclaw_enhance

增强配置详见：
#[[file:~/.openclaw/workspace/system/openclaw-enhance/agents/${agent_name}.md]]"
    
    if [ -f "$agents_md" ]; then
        if ! grep -q "# openclaw_enhance" "$agents_md"; then
            echo "更新 $agent_name AGENTS.md..."
            backup_existing "$agents_md" "agents" "${workspace_type}/${agent_name}/AGENTS"
            echo "$agents_section" >> "$agents_md"
            update_manifest "agents" "${agent_name}/AGENTS" '{"type":"section","action":"appended","has_backup":True}'
        fi
    else
        echo "创建 $agent_name AGENTS.md..."
        echo "$agents_section" > "$agents_md"
        update_manifest "agents" "${agent_name}/AGENTS" '{"type":"section","action":"created","has_backup":False}'
    fi
    
    # 处理 TOOLS.md
    tools_md="$target_dir/TOOLS.md"
    tools_section="
# openclaw_enhance

增强工具详见：
#[[file:~/.openclaw/workspace/system/openclaw-enhance/agents/${agent_name}-tools.md]]"
    
    if [ -f "$tools_md" ]; then
        if ! grep -q "# openclaw_enhance" "$tools_md"; then
            echo "更新 $agent_name TOOLS.md..."
            backup_existing "$tools_md" "agents" "${workspace_type}/${agent_name}/TOOLS"
            echo "$tools_section" >> "$tools_md"
            update_manifest "agents" "${agent_name}/TOOLS" '{"type":"section","action":"appended","has_backup":True}'
        fi
    fi
done

echo "==> 部署 main agent..."
main_agents_md="${OPENCLAW_HOME}/workspace/AGENTS.md"
main_section="
# openclaw_enhance

增强配置详见：
#[[file:~/.openclaw/workspace/system/openclaw-enhance/agents/main.md]]"

if [ -f "$main_agents_md" ]; then
    if ! grep -q "# openclaw_enhance" "$main_agents_md"; then
        echo "更新 main AGENTS.md..."
        backup_existing "$main_agents_md" "agents" "main/AGENTS"
        echo "$main_section" >> "$main_agents_md"
        update_manifest "agents" "main/AGENTS" '{"type":"section","action":"appended","has_backup":True}'
    fi
fi

echo "==> 安装完成！"
echo "配置已部署到: ${SYSTEM_DIR}"
echo "安装清单: ${MANIFEST}"
