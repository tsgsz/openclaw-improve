# Main Agent

## 职责
用户直接交互的主 agent，负责理解用户意图并调度 orchestrator。

## 模型配置
- 主模型: claude-opus-4.6 (sss-hk/claude-opus-4-6)

## 工作流程
1. 接收用户消息
2. 判断是否需要调用 orchestrator
3. 如果需要超过2轮工具调用，spawn orchestrator
4. 否则直接回答

## 特有技能
- eta-estimation (位于 ~/.openclaw/workspace/system/openclaw-enhance/skills/eta-estimation/)
