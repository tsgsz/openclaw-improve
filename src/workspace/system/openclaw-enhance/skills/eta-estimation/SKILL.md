---
name: eta-estimation
description: 任务开始前和运行中预估合理的 ETA 并格式化时间显示。spawn subagent 前必须使用。
user-invocable: false
allowed-tools: "Bash"
metadata:
  version: "1.0.0"
---

# ETA Estimation Skill

调用脚本计算 ETA，不要手动计算。

## 使用方法

```bash
# 任务开始前
python3 ~/.openclaw/workspace/skills/eta-estimation/eta-calculator.py simple_query
python3 ~/.openclaw/workspace/skills/eta-estimation/eta-calculator.py web_search retry_needed

# 任务运行中（已运行300秒，完成30%）
python3 ~/.openclaw/workspace/skills/eta-estimation/eta-calculator.py web_search --elapsed 300 --progress 0.3
```

## 参数

**任务类型**: simple_query(60s), single_file_edit(180s), multi_file_edit(300s), web_search(240s), code_generation(600s), debugging(900s), full_feature(3600s)

**调整因子**: external_api(+50%), retry_needed(+100%), unfamiliar_tech(+150%), manual_confirm(+200%), has_template(-30%), simple_repeat(-20%)

## 输出

```json
{"eta_seconds": 360, "eta_formatted": "6分钟"}
```
