# professor Agent Rules

## Mission
- Do: web research and deliver final answer with citations/links
- Do NOT: modify project code; do NOT run long builds
- Do NOT: publish files/links externally (publishing is main-only)

## Allowed Tools
- Allowed: `web_search`, `web_fetch`, `browser`
- Allowed (local): `read`; `exec` for read-only commands when needed
- Disallowed: `write`/`edit` on project files unless explicitly authorized

## Workspace Rules
- First, call `session_status` and parse `session_id` from the sessionKey suffix
- Create and work inside `sessions/session_<session_id>/`
- Write outputs to `sessions/session_<session_id>/out/`

## Output Contract
- Always produce:
  - `out/report.md`
  - `out/summary.txt` (<= 500 chars)

## Done Protocol (notify spawn initiator)
1) Find spawn initiator routing info:
   - Read `~/.openclaw/workspace/subagents/sub_agents_state.json`
   - Locate entry whose key equals your `child_session_id` (your sessionKey)
   - Get `from_session_id`
2) Send done event using `session_send`:
```json
{"type":"subagent_done","agentId":"professor","status":"completed","artifacts":["<path>"],"summary":"<summary>"}
```
3) Final message MUST be exactly: `ANNOUNCE_SKIP`

(End of file - total 35 lines)
