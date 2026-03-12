#!/usr/bin/env bash
set -euo pipefail

VAULT_PATH="${1:-$HOME/workspace/知识库}"

mkdir -p "$VAULT_PATH"/{00-Inbox,01-MOC,02-Notes,03-Projects,04-Areas,05-Resources,06-Archives,07-Templates,08-Attachments}

# Starter index notes (create only if absent)
for f in \
  "$VAULT_PATH/01-MOC/MOC-首页.md" \
  "$VAULT_PATH/01-MOC/MOC-项目.md" \
  "$VAULT_PATH/01-MOC/MOC-领域.md" \
  "$VAULT_PATH/07-Templates/TPL-永久笔记.md" \
  "$VAULT_PATH/07-Templates/TPL-每日笔记.md" \
  "$VAULT_PATH/07-Templates/TPL-每周复盘.md"; do
  if [ ! -f "$f" ]; then
    touch "$f"
  fi
done

if [ ! -s "$VAULT_PATH/07-Templates/TPL-永久笔记.md" ]; then
cat > "$VAULT_PATH/07-Templates/TPL-永久笔记.md" <<'MD'
---
type: note
status: seed
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
tags:
  - notes/permanent
---

# {{title}}

## 结论

## 关键要点

## 关联
- 上游：
- 下游：
MD
fi

if [ ! -s "$VAULT_PATH/07-Templates/TPL-每日笔记.md" ]; then
cat > "$VAULT_PATH/07-Templates/TPL-每日笔记.md" <<'MD'
---
type: daily
date: {{date:YYYY-MM-DD}}
tags:
  - journal/daily
---

# {{date:YYYY-MM-DD}} 日志

## Inbox 清理
- [ ]

## 今日三件事
- [ ]
- [ ]
- [ ]

## 新增链接
- [[]]
MD
fi

if [ ! -s "$VAULT_PATH/07-Templates/TPL-每周复盘.md" ]; then
cat > "$VAULT_PATH/07-Templates/TPL-每周复盘.md" <<'MD'
---
type: weekly
week: {{date:gggg-[W]ww}}
tags:
  - review/weekly
---

# {{date:gggg-[W]ww}} 周复盘

## 本周产出

## 失焦与原因

## 下周优先级
1. 
2. 
3. 
MD
fi

echo "Applied Obsidian KM scaffold to: $VAULT_PATH"
