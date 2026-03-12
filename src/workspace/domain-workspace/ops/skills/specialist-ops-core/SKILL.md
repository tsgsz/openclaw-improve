---
name: specialist-ops-core
version: 1.0.0
description: specialist-ops 内部核心规则（status->plan->execute，安全确认点）。
---

# Specialist Ops Core

## 顺序

1) status/证据
2) 计划（含回滚）
3) 执行建议（需要明确确认点则提出）

## 禁止

- 未确认前扩大暴露面（例如公开 dashboard）
