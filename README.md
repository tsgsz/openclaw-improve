# openclaw-improve

这是一个用于对 openclaw 进行增强的项目。
这个项目的目标是用一系列不侵入 openclaw 原生代码的改动对 openclaw 进行增强。

## ✅ Task Dispatch Plugin - 已完成

**状态**: 实现完成，50/50 任务完成

### 解决的问题

1. Spawn Subagent 之后很容易失联
2. Subagent 直接回复用户，main 无法处理中间任务
3. main 决策不稳定

### 解决方案

- **task_sync**: 同步任务派发，保证结果返回
- **task_async**: 异步任务跟踪，支持并发
- **task_check**: 查询任务状态
- **subagent_ended hook**: 自动捕获完成事件
- **LRU registry**: 内存管理

### 安装

```bash
cd plugin
chmod +x install.sh
./install.sh
```

### 文档

- `plugin/README.md` - 完整文档
- `specs/001-task-dispatch-plugin/` - 设计文档
- `plugin/tests/manual/test-scenarios.md` - 测试场景
