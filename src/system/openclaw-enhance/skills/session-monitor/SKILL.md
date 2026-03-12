---
name: session-monitor
description: 监控特定 session 的状态，判断任务是否完成/失败/需要延长。由 runtime-monitor 触发。
user-invocable: false
allowed-tools: "session_list, session_read, session_send, Bash"
metadata:
  version: "1.0.0"
---

# Session Monitor Skill

## 职责

检查特定 session 的实际状态，做非标准化判断。

## 触发方式

当 runtime-monitor.py 检测到任务超时时，会调用 watchdog agent 并传递：
- sessionKey: 要检查的 session
- runId: 对应的 run ID
- elapsed: 已运行时间（秒）

## 工作流程

1. **获取 session 信息**
   ```
   使用 session_list 找到对应的 session
   使用 session_read 读取最近的对话记录
   ```

2. **分析状态**
   - 检查最后一条消息的时间和内容
   - 查看是否有完成标志
   - 判断是否在等待用户输入
   - 检查是否遇到错误但还在重试
   - 分析工具调用是否正常

3. **做出判断**
   - **已完成**: 任务实际已完成
   - **失败**: 任务卡住或失败
   - **需要延长**: 任务正常进行但需要更多时间

4. **执行操作并通知 orchestrator**
   
   **所有情况都必须通知 orchestrator**:
   
   ```bash
   # 情况1: 已完成
   python3 ~/.openclaw/workspace/scripts/runtime-monitor.py complete {runId}
   # 使用 session_send 通知 orchestrator: "任务 {runId} 已完成"
   
   # 情况2: 需要延长
   python3 ~/.openclaw/workspace/scripts/runtime-monitor.py update-eta {runId} {newETA}
   # 使用 session_send 通知 orchestrator: "任务 {runId} 需要延长至 {newETA}秒"
   
   # 情况3: 失败
   # 使用 session_send 通知 orchestrator: "任务 {runId} 失败: {原因}"
   ```

## 判断依据

### 完成标志
- 消息中包含 "完成"、"done"、"finished"
- 最后的工具调用是 ANNOUNCE
- 没有待处理的工具调用

### 等待用户输入
- 最后一条消息是问题
- 包含选项让用户选择
- 明确说明需要用户确认

### 正常进行
- 工具调用持续进行
- 有进度更新
- 没有重复的错误

### 失败/卡住
- 同样的错误重复出现
- 工具调用失败且没有重试
- 长时间没有新消息且未完成
