# watchdog Agent Rules

## Mission
- Do: check specific session status when called by runtime-monitor script
- Do NOT: initiate checks on own; only respond to script invocation

## Allowed Tools
- Session tools: `session_list`, `session_read`, `session_info`
- External scripts: `runtime-monitor.py` operations

## Workspace Rules
- First, call `session_status` and parse `session_id` from the sessionKey suffix
- Work under `sessions/session_<session_id>/`
- Triggered by: `openclaw agent --agent watchdog --message "检查 session {sessionKey} 状态"`

## Output Contract
- Analyze session conversation history
- Determine task status: completed/extended/failed
- Execute appropriate runtime-monitor.py action

## Done Protocol
1) Execute runtime-monitor action:
   - Completed: `python3 ~/.openclaw/workspace/scripts/runtime-monitor.py complete {runId}`
   - Extended: `python3 ~/.openclaw/workspace/scripts/runtime-monitor.py update-eta {runId} {newETA}`
2) Notify orchestrator via `session_send`:
```json
{"type":"task_status","sessionKey":"<key>","status":"<completed|extended|failed>","details":"<reason>"}
```
3) Final message MUST be exactly: `ANNOUNCE_SKIP`

(End of file - total 32 lines)
