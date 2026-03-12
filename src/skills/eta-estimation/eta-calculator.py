#!/usr/bin/env python3
import json
import sys

TASK_BASE_ETA = {
    "simple_query": 60,
    "single_file_edit": 180,
    "multi_file_edit": 300,
    "web_search": 240,
    "code_generation": 600,
    "debugging": 900,
    "full_feature": 3600,
}

ADJUSTMENT_FACTORS = {
    "external_api": 1.5,
    "retry_needed": 2.0,
    "unfamiliar_tech": 2.5,
    "manual_confirm": 3.0,
    "has_template": 0.7,
    "simple_repeat": 0.8,
}


def format_time(seconds):
    if seconds < 60:
        return f"{seconds}秒"
    elif seconds < 3600:
        minutes = seconds // 60
        return f"{minutes}分钟"
    elif seconds < 86400:
        hours = seconds // 3600
        return f"{hours}小时"
    else:
        days = seconds // 86400
        return f"{days}天"


def estimate_eta(task_type, adjustments=None, elapsed=None, progress=None):
    if task_type not in TASK_BASE_ETA:
        return {"error": f"Unknown task type: {task_type}"}

    base_eta = TASK_BASE_ETA[task_type]

    if elapsed is not None and progress is not None:
        total = elapsed / progress if progress > 0 else elapsed * 2
        remaining = total - elapsed
        eta = int(remaining * 1.5)
    else:
        eta = base_eta

        if adjustments:
            for adj in adjustments:
                if adj in ADJUSTMENT_FACTORS:
                    eta = int(eta * ADJUSTMENT_FACTORS[adj])

    return {"eta_seconds": eta, "eta_formatted": format_time(eta)}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            json.dumps(
                {
                    "error": "Usage: eta-calculator.py <task_type> [adjustments...] [--elapsed <sec> --progress <0-1>]"
                }
            )
        )
        sys.exit(1)

    task_type = sys.argv[1]
    adjustments = []
    elapsed = None
    progress = None

    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--elapsed":
            elapsed = int(sys.argv[i + 1])
            i += 2
        elif sys.argv[i] == "--progress":
            progress = float(sys.argv[i + 1])
            i += 2
        else:
            adjustments.append(sys.argv[i])
            i += 1

    result = estimate_eta(task_type, adjustments, elapsed, progress)
    print(json.dumps(result))
