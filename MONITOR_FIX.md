# Monitor 和 Watchdog 实现修复

## 问题
1. runtime-monitor 检测到超时后没有主动通知 watchdog
2. watchdog 缺少专门的 skill 指导如何处理

## 解决方案

### 1. 创建 Watchdog Skill
**位置**: `src/functional-workspace/watchdog/skills/session-monitor.md`

**内容**:
- 详细的工作流程
- 判断依据（完成/失败/延长）
- 具体操作命令

### 2. 更新 runtime-monitor.py
**修改**: `check_timeouts()` 函数

**新增功能**:
```python
def spawn_watchdog(run_id, session_key, elapsed):
    # 调用 openclaw agent 命令
    openclaw agent --agent watchdog --message "..." --thinking low
```

**触发时机**: 当检测到 `elapsed > currentETA` 时自动调用

### 3. 更新 Watchdog AGENTS.md
**新增**:
- 触发方式说明
- 具体命令格式
- 执行操作的脚本命令
- Skill 引用

## 工作流程

```
runtime-monitor.py (cron 每分钟)
  ↓ 检测超时
  ↓ 调用: openclaw agent --agent watchdog
  ↓
watchdog agent
  ↓ 读取 skills/session-monitor.md
  ↓ 使用 session_list, session_read
  ↓ 分析状态
  ↓
  ├─ 已完成 → runtime-monitor.py complete {runId}
  ├─ 需要延长 → runtime-monitor.py update-eta {runId} {newETA}
  └─ 失败 → session_send 通知 orchestrator
```

## 测试结果
✅ 所有测试通过
