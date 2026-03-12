#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

OPENCLAW_HOME = Path.home() / ".openclaw"
RUNTIME_JSON = OPENCLAW_HOME / "subagents" / "runtime.json"
RUNS_JSON = OPENCLAW_HOME / "subagents" / "runs.json"


def ensure_runtime():
    RUNTIME_JSON.parent.mkdir(parents=True, exist_ok=True)
    if not RUNTIME_JSON.exists():
        RUNTIME_JSON.write_text(json.dumps({"tasks": {}}, indent=2))


def load_runtime():
    ensure_runtime()
    return json.loads(RUNTIME_JSON.read_text())


def save_runtime(data):
    RUNTIME_JSON.write_text(json.dumps(data, indent=2))


def load_runs():
    if not RUNS_JSON.exists():
        return {"runs": {}}
    return json.loads(RUNS_JSON.read_text())


def record_spawn(run_id, session_key, project, eta, timeout):
    data = load_runtime()
    data["tasks"][run_id] = {
        "sessionKey": session_key,
        "project": project,
        "eta": eta,
        "timeout": timeout if timeout > 0 else eta * 3,
        "startTime": int(datetime.now(timezone.utc).timestamp() * 1000),
        "extensions": 0,
        "currentETA": eta,
    }
    save_runtime(data)
    print(json.dumps({"success": True}))


def check_timeouts():
    runtime = load_runtime()
    runs = load_runs()
    now = int(datetime.now(timezone.utc).timestamp() * 1000)

    active_runs = set(runs.get("runs", {}).keys())
    timeouts = []
    completed = []

    for run_id, task in runtime["tasks"].items():
        if run_id not in active_runs:
            completed.append(run_id)
            continue

        elapsed = now - task["startTime"]
        if elapsed > task["currentETA"] * 1000:
            timeout_info = {
                "runId": run_id,
                "sessionKey": task["sessionKey"],
                "elapsed": elapsed // 1000,
            }
            timeouts.append(timeout_info)

            spawn_watchdog(run_id, task["sessionKey"], elapsed // 1000)

    print(json.dumps({"timeouts": timeouts, "completed": completed}))


def spawn_watchdog(run_id, session_key, elapsed):
    message = f"任务超时告警。sessionKey: {session_key}, runId: {run_id}, 已运行: {elapsed}秒。请使用session_list和session_read检查任务状态，然后执行操作并通知orchestrator：1)已完成: 运行 python3 ~/.openclaw/workspace/scripts/runtime-monitor.py complete {run_id} 并用session_send通知orchestrator任务完成 2)需要延长: 运行 python3 ~/.openclaw/workspace/scripts/runtime-monitor.py update-eta {run_id} <新ETA秒数> 并用session_send通知orchestrator延长原因 3)失败: 用session_send通知orchestrator失败原因。所有情况都必须通知orchestrator。"
    os.system(
        f'openclaw agent --agent watchdog --message "{message}" --thinking low > /dev/null 2>&1 &'
    )


def update_eta(run_id, new_eta):
    data = load_runtime()
    if run_id not in data["tasks"]:
        print(json.dumps({"error": "Task not found"}))
        sys.exit(1)

    data["tasks"][run_id]["currentETA"] = new_eta
    data["tasks"][run_id]["extensions"] += 1
    save_runtime(data)
    print(json.dumps({"success": True}))


def mark_completed(run_id):
    data = load_runtime()
    if run_id in data["tasks"]:
        del data["tasks"][run_id]
        save_runtime(data)
    print(json.dumps({"success": True}))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: runtime-monitor.py <command> [args]")
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "record":
        record_spawn(
            sys.argv[2], sys.argv[3], sys.argv[4], int(sys.argv[5]), int(sys.argv[6])
        )
    elif cmd == "check":
        check_timeouts()
    elif cmd == "update-eta":
        update_eta(sys.argv[2], int(sys.argv[3]))
    elif cmd == "complete":
        mark_completed(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
