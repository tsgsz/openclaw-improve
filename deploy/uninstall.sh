#!/bin/bash
set -e

OPENCLAW_HOME="${OPENCLAW_HOME:-${HOME}/.openclaw}"

if [ "$1" = "--openclaw-home" ]; then
    OPENCLAW_HOME="$2"
fi

SYSTEM_DIR="${OPENCLAW_HOME}/workspace/system/openclaw-enhance"
MANIFEST="${SYSTEM_DIR}/manifest.json"

echo "使用 Openclaw 目录: ${OPENCLAW_HOME}"
echo "==> 卸载 Openclaw 增强形态"

if [ ! -f "$MANIFEST" ]; then
    echo "未找到安装清单，可能未安装或已卸载"
    exit 1
fi

echo "==> 读取安装清单..."
SKILLS=$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(' '.join([k for k,v in m['skills'].items() if v.get('type')!='skipped']))" 2>/dev/null || echo "")
HOOKS=$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(' '.join([k for k,v in m['hooks'].items() if v.get('type')!='skipped']))" 2>/dev/null || echo "")
PLUGINS=$(python3 -c "import json; m=json.load(open('$MANIFEST')); print(' '.join([k for k,v in m['plugins'].items() if v.get('type')!='skipped']))" 2>/dev/null || echo "")

echo "==> 删除 skills 软链..."
for skill in $SKILLS; do
    target="${OPENCLAW_HOME}/workspace/skills/${skill}"
    if [ -L "$target" ]; then
        echo "删除软链: $skill"
        rm -f "$target"
    fi
done

echo "==> 卸载 hooks..."
for hook in $HOOKS; do
    echo "卸载 hook: $hook"
    openclaw hooks delete "$hook" 2>/dev/null || true
done

echo "==> 卸载 plugins..."
for plugin in $PLUGINS; do
    echo "卸载 plugin: $plugin"
    openclaw plugins uninstall "$plugin" 2>/dev/null || true
done

echo "==> 还原备份..."
python3 << 'PYTHON'
import json, shutil, os
manifest_path = os.path.expanduser("${MANIFEST}")
if os.path.exists(manifest_path):
    with open(manifest_path) as f:
        m = json.load(f)
    for backup in m.get('backups', []):
        src = os.path.expanduser(f"${SYSTEM_DIR}/{backup['backup_path']}")
        if backup['path'].startswith('agents/'):
            agent_path = backup['path'].replace('agents/', '')
            dst = os.path.expanduser(f"${OPENCLAW_HOME}/workspace/{agent_path}/AGENTS.md")
        else:
            dst = os.path.expanduser(f"${OPENCLAW_HOME}/workspace/{backup['path']}")
        if os.path.exists(src):
            print(f"还原: {backup['path']}")
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(src, dst)
PYTHON

echo "==> 清理新创建的 AGENTS.md..."
python3 << 'PYTHON'
import json, os
manifest_path = os.path.expanduser("${MANIFEST}")
if os.path.exists(manifest_path):
    with open(manifest_path) as f:
        m = json.load(f)
    for agent, info in m.get('agents', {}).items():
        if info.get('action') == 'created':
            for ws in ['functional-workspace', 'domain-workspace']:
                agent_file = os.path.expanduser(f"${OPENCLAW_HOME}/workspace/{ws}/{agent}/AGENTS.md")
                if os.path.exists(agent_file):
                    print(f"删除: {ws}/{agent}/AGENTS.md")
                    os.remove(agent_file)
PYTHON

echo "==> 清理 scripts..."
rm -f "${OPENCLAW_HOME}/workspace/scripts/tools/project-manager.py"
rm -f "${OPENCLAW_HOME}/workspace/scripts/tools/runtime-monitor.py"

echo "==> 删除系统目录..."
rm -rf "${SYSTEM_DIR}"

echo "==> 卸载完成！所有组件已还原。"
