# 实现细节

## 核心问题和解决方案

### 问题1: 如何在 spawn 前强制选择项目

**调研结果**: OpenClaw 提供 `subagent_spawning` Plugin Hook（spawn 之前触发，可阻止）

**解决方案**:
1. 使用 `message_received` Plugin Hook 标记项目
2. 使用 `subagent_spawning` Plugin Hook 验证项目选择（未选择则阻止 spawn）
3. 通过 `workspaceDir` 参数传递工作目录

### 问题2: 如何监控 spawn 状态

**调研结果**: 
- `~/.openclaw/subagents/runs.json` 记录当前运行的任务
- 没有原生的 ETA 和监控机制

**解决方案**:
1. 新增 `~/.openclaw/subagents/runtime.json` 存储 ETA 信息
2. Python 脚本定期对比 runs.json 和 runtime.json
3. 超时后 spawn watchdog agent 检查

### 问题3: Agent 配置方式

**调研结果**: 
- Agent 不是用单个 agent.json
- 配置在 `~/.openclaw/openclaw.json` 的 `agents.defaults` 中
- 每个 agent 目录下有 models.json

**解决方案**:
- 在 openclaw.json 中配置各 agent 的模型偏好
- 保持现有目录结构不变

## 待确认问题

1. **如何在 spawn 时注入项目信息？**
   - 方案A: 修改 sessions_spawn tool 源码（侵入性大）
   - 方案B: orchestrator 读取消息中的项目标签，手动传 cwd（推荐）

2. **ETA 如何预估？**
   - 方案A: 固定规则（orchestrator: 300s）
   - 方案B: 基于历史数据
   - 建议: 先用固定规则

3. **项目语义匹配算法？**
   - 使用 LLM 进行语义判断
   - 提供项目列表和用户消息给 LLM
   - LLM 返回最匹配的项目名称

## 下一步

需要你确认：
1. 是否接受方案B（orchestrator 手动读取项目标签）？
2. ETA 固定规则是否可行？
3. 是否需要修改 openclaw 源码，还是纯扩展？
