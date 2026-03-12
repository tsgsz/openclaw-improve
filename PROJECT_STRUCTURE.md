# 项目结构

```
openclaw-improve/
├── src/                          # 开发源码
│   ├── scripts/                  # Python 脚本
│   │   ├── project-manager.py    # 项目管理
│   │   └── runtime-monitor.py    # 运行时监控
│   ├── plugins/                  # OpenClaw 插件
│   │   ├── spawn-monitor/        # Spawn 监控插件
│   │   │   ├── index.ts
│   │   │   └── package.json
│   │   └── project-loader/       # 项目加载插件
│   │       ├── index.ts
│   │       └── package.json
│   ├── functional-workspace/     # 功能型 Agent
│   │   ├── orchestrator/
│   │   ├── professor/
│   │   ├── systemhelper/
│   │   ├── scriptproducer/
│   │   ├── reviewer/
│   │   └── watchdog/
│   └── domain-workspace/         # 领域型 Agent
│       ├── ops/
│       ├── game-design/
│       ├── finance/
│       ├── creative/
│       └── km/
├── tests/                        # 测试脚本
│   ├── test-project-manager.sh
│   ├── test-runtime-monitor.sh
│   └── run-all-tests.sh
├── deploy/                       # 部署脚本
│   ├── install.sh
│   ├── update.sh
│   ├── uninstall.sh
│   └── README.md
├── docs/                         # 设计文档
└── README.md
```

## 部署目标

部署后的文件位置：

```
~/.openclaw/
├── bin/
│   ├── project-manager.py
│   └── runtime-monitor.py
├── plugins/
│   ├── spawn-monitor/
│   └── project-loader/
└── workspace/
    ├── functional-workspace/
    │   ├── orchestrator/
    │   ├── professor/
    │   ├── systemhelper/
    │   ├── scriptproducer/
    │   ├── reviewer/
    │   └── watchdog/
    └── domain-workspace/
        ├── ops/
        ├── game-design/
        ├── finance/
        ├── creative/
        └── km/
```
