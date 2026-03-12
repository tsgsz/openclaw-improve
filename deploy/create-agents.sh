#!/bin/bash
set -e

echo "==> 创建 Functional Agents"

openclaw agents add orchestrator \
  --workspace ~/.openclaw/workspace/functional-workspace/orchestrator \
  --model sss-hk/claude-opus-4-6 || echo "orchestrator 已存在"

openclaw agents add professor \
  --workspace ~/.openclaw/workspace/functional-workspace/professor \
  --model kimi-coding/k2p5 || echo "professor 已存在"

openclaw agents add systemhelper \
  --workspace ~/.openclaw/workspace/functional-workspace/systemhelper \
  --model kimi-coding/k2p5 || echo "systemhelper 已存在"

openclaw agents add scriptproducer \
  --workspace ~/.openclaw/workspace/functional-workspace/scriptproducer \
  --model openai-codex/gpt-codex-5.3 || echo "scriptproducer 已存在"

openclaw agents add reviewer \
  --workspace ~/.openclaw/workspace/functional-workspace/reviewer \
  --model google/gemini-3.1-pro-preview || echo "reviewer 已存在"

openclaw agents add watchdog \
  --workspace ~/.openclaw/workspace/functional-workspace/watchdog \
  --model minimax/MiniMax-M2.1 || echo "watchdog 已存在"

echo "==> 创建 Domain Agents"

openclaw agents add ops \
  --workspace ~/.openclaw/workspace/domain-workspace/ops \
  --model minimax/MiniMax-M2.1 || echo "ops 已存在"

openclaw agents add game-design \
  --workspace ~/.openclaw/workspace/domain-workspace/game-design \
  --model openai-codex/gpt-5.4 || echo "game-design 已存在"

openclaw agents add finance \
  --workspace ~/.openclaw/workspace/domain-workspace/finance \
  --model google/gemini-3.1-pro-preview || echo "finance 已存在"

openclaw agents add creative \
  --workspace ~/.openclaw/workspace/domain-workspace/creative \
  --model google/gemini-3.1-pro-preview || echo "creative 已存在"

openclaw agents add km \
  --workspace ~/.openclaw/workspace/domain-workspace/km \
  --model openai-codex/gpt-5.4 || echo "km 已存在"

echo "==> 所有 agents 创建完成"
