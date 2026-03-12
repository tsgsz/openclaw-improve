# Scripts 组织规范

参考 `~/.openclaw/workspace/scripts/README.md`

## 硬规则

- `scripts/` 顶层不放脚本文件（只放分组目录 + README）
- 按功能分组到子目录

## 本项目结构

```
src/scripts/
├── README.md
└── tools/
    ├── project-manager.py
    └── runtime-monitor.py
```

## 分组说明

- `tools/` - 小工具脚本

## 注意

- skill 专属脚本放在 `skills/<name>/` 目录下，不放在 scripts/
